require 'timeout'
require 'pathname'
require 'tmpdir'
require 'daemon'
require 'shellwords'
require 'thwait'
require 'micromachine'

module CucumberSpawnProcess
	class BackgroundProcess
		class ProcessExitedError < RuntimeError
			def initialize(process, exit_code)
				super "process #{process} exited with exit code: #{exit_code}"
			end
		end

		class ProcessReadyFailedError < RuntimeError
			def initialize(process)
				super "process #{process} readiness check failed"
			end
		end

		class ProcessReadyTimeOutError < Timeout::Error
			def initialize(process)
				super "process #{process} failed to start in time"
			end
		end

		class ProcessRunAwayError < RuntimeError
			def initialize(process, pid)
				super "process #{process} could not be stopped; pid: #{pid}"
			end
		end

		def initialize(name, cmd, args = [], working_directory = nil, options = {})
			@name = name

			@exec = (Pathname.new(Dir.pwd) + cmd).cleanpath.to_s
			@args = args.map(&:to_s)
			@command = nil # built on startup

			@pid = nil
			@process = nil

			@state_log = []

			case working_directory
			when Array
				working_directory = Dir.mktmpdir(working_directory)
			when nil
				working_directory = Dir.mktmpdir(name.to_s)
			end

			@working_directory = Pathname.new(working_directory.to_s)
			@working_directory.directory? or @working_directory.mkdir

			@pid_file = @working_directory + "#{@name}.pid"
			@log_file = @working_directory + "out.log"

			@options = options
			reset_options(options)

			@fsm_lock = Mutex.new

			@_fsm = MicroMachine.new(:not_running)

			@state_change_time = Time.now.to_f
			@after_state_change = []

			@_fsm.on(:any) do
				@state_change_time = Time.now.to_f
				puts "process is now #{@_fsm.state}"
				@after_state_change.each{|callback| callback.call(@_fsm.state)}
			end

			@_fsm.when(:starting,
				not_running: :starting
			)

			@_fsm.on(:starting) do
				puts "starting: `#{@command}`"
				puts "working directory: #{@working_directory}"
				puts "log file: #{@log_file}"
			end

			@_fsm.when(:started,
				starting: :running
			)
			@_fsm.on(:running) do
				puts "running with pid: #{@pid}"
			end

			@_fsm.when(:stopped,
				running: :not_running,
				ready: :not_running
			)

			@_fsm.when(:died,
				starting: :dead,
				running: :dead,
				ready: :dead
			)

			# it is topped before marked failed
			@_fsm.when(:failed,
				not_running: :failed
			)

			@_fsm.when(:verified,
				running: :ready,
				ready: :ready,
			)
			@_fsm.when(:run_away,
				running: :jammed,
				ready: :jammed
			)

			@template_renderer = options[:template_renderer]

			# make sure we stop on exit
			my_pid = Process.pid
			at_exit do
				stop if Process.pid == my_pid and running? #only run in master process
			end
		end

		def render(str)
			if @template_renderer
				@template_renderer.call(template_variables, str)
			else
				str
			end
		end

		def template_variables
			{
				/working directory/ => -> { working_directory },
				/pid file/ => -> { pid_file },
				/pid/ => -> { pid },
				/log file/ => -> { log_file },
				/name/ => -> { name },
			}
		end

		def command
			# update arguments with actual port numbers, working directories etc. (see template variables)
			Shellwords.join([@exec, *@args.map{|arg| render(arg)}])
		end

		attr_reader :name
		attr_reader :working_directory
		attr_reader :pid_file
		attr_reader :log_file
		attr_reader :ready_timeout
		attr_reader :term_timeout
		attr_reader :kill_timeout
		attr_reader :state_change_time
		attr_reader :state_log

		def reset_options(opts)
			@logging = opts[:logging]

			@ready_timeout = opts[:ready_timeout] || 10
			@term_timeout = opts[:term_timeout] || 10
			@kill_timeout = opts[:kill_timeout] || 10

			@ready_test = opts[:ready_test] || ->(_){true}
			@refresh_action = opts[:refresh_action] || ->(_){restart}
		end

		def pid
			@pid if running?
		end

		def exit_code
			@process.value.exitstatus if not running? and @process
		end

		def running?
			trigger? :stopped # if it can be stopped it must be running :D
		end

		def ready?
			state == :ready
		end

		def dead?
			state == :dead
		end

		def failed?
			state == :failed
		end

		def jammed?
			state == :jammed
		end

		def state
			lock_fsm{|fsm| fsm.state }
		end

		def refresh
			puts 'refreshing'
			cwd = Dir.pwd
			begin
				Dir.chdir(@working_directory.to_s)
				@refresh_action.call(self)
			ensure
				Dir.chdir(cwd)
			end
			self
		end

		def restart
			puts 'restarting'
			stop
			start
		end

		def start
			return self if trigger? :stopped
			trigger? :starting or fail "can't start when: #{state}"

			@command ||= command
			trigger :starting
			@pid, @process = spawn

			@process_watcher = Thread.new do
				@process.join
				trigger :died
			end

			trigger :started
			self
		end

		def stop
			return if trigger? :started
			trigger? :stopped or fail "can't stop while: #{state}"

			# get rid of the watcher thread
			@process_watcher and @process_watcher.kill and @process_watcher.join

			catch :done do
				begin
					if @term_timeout > 0
						puts "terminating process: #{@pid}"
						Process.kill("TERM", @pid)
						@process.join(@term_timeout) and throw :done
						puts "process #{@pid} did not terminate in time"
					end

					if @kill_timeout > 0
						puts "killing process: #{@pid}"
						Process.kill("KILL", @pid)
						@process.join(@kill_timeout) and throw :done
						puts "process #{@pid} could not be killed!!!"
					end
				rescue Errno::ESRCH
					throw :done
				end

				trigger :run_away
				raise ProcessRunAwayError.new(self.to_s, @pid)
			end

			trigger :stopped
			self
		end

		def wait_ready
			trigger? :verified or fail "can't verify when: #{state}"

			puts 'verifying'

			status = while_running do
				begin
					Timeout.timeout(@ready_timeout) do
						@ready_test.call(self) ? :ready : :failed
					end
				rescue Timeout::Error
					:ready_timeout
				end
			end

			case status
			when :failed
				puts "process failed to pass it's readiness test"
				stop
				trigger :failed
				raise ProcessReadyFailedError.new(self.to_s)
			when :ready_timeout
				puts "process not ready in time; see #{log_file} for detail"
				stop
				trigger :failed
				raise ProcessReadyTimeOutError.new(self.to_s)
			when Exception
				puts "process readiness check raised error: #{status}; see #{log_file} for detail"
				stop
				trigger :failed
				raise status
			else
				trigger :verified
				self
			end
		end

		def after_state_change(&callback)
			@after_state_change << callback
		end

		def puts(message)
			message = "#{name}: #{message}"
			@state_log << message
			super message if @logging
		end

		def to_s
			"#{name}[#{@exec}](#{state})"
		end

		private

		def lock_fsm
			@fsm_lock.synchronize{yield @_fsm}
		end

		def trigger(change)
			lock_fsm{|fsm| fsm.trigger(change)}
		end

		def trigger?(change)
			lock_fsm{|fsm| fsm.trigger?(change)}
		end

		def spawn
			Daemon.daemonize(@pid_file, @log_file) do |log|
				prepare_process(log, 'exec')
				# TODO: looks like exec is eating pending TERM (or other) signal and .start.stop may time out on TERM if signal was delivered before exec?
				Kernel.exec(@command)
			end
		end

		def while_running
			action = Thread.new do
				begin
					yield
				rescue => error
					error
				end
			end

			value = ThreadsWait.new.join(action, @process).value
			case value
			when Process::Status
				puts "process exited; see #{log_file} for detail"
				trigger :died
				raise ProcessExitedError.new(self.to_s, exit_code)
			end

			value
		end

		def prepare_process(log, type)
			log.truncate(0)
			Dir.chdir(@working_directory.to_s)

			# useful for testing
			ENV['PROCESS_SPAWN_TYPE'] = type
		end
	end

	class LoadedBackgroundProcess < BackgroundProcess
		private

		# cmd will be loaded in forked ruby interpreter and arguments passed via ENV['ARGS']
		# This way starting new process will be much faster since ruby VM is already loaded
		def spawn
			cmd = Shellwords.split(@command)
			file = cmd.shift

			puts "loading ruby script: #{file}"
			Daemon.daemonize(@pid_file, @log_file) do |log|
				prepare_process(log, 'load')

				# reset ARGV
				Object.instance_eval{ remove_const(:ARGV) }
				Object.const_set(:ARGV, cmd)

				# reset $0
				$0 = file

				# reset $*
				$*.replace(cmd)

				load file

				# make sure we exit if loaded file won't
				exit 0
			end
		end
	end
end
