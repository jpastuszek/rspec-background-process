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

		def initialize(name, cmd, args = [], working_directory = Dir.mktmpdir(name), options = {})
			@name = name
			@command = Shellwords.join([cmd, *args.map(&:to_s)])

			@pid = nil
			@process = nil

			@working_directory = Pathname.new working_directory
			@working_directory.directory? or @working_directory.mkdir

			@pid_file = @working_directory + "#{@name}.pid"
			@log_file = @working_directory + "#{@name}.log"

			reset_options(options)

			@fsm_lock = Mutex.new

			@_fsm = MicroMachine.new(:not_running)
			@_fsm.on(:any) do
				puts "process is now #{@_fsm.state}"
			end

			@_fsm.when(:started,
				not_running: :running
			)
			@_fsm.on(:running) do
				puts "running with pid: #{@pid}"
			end

			@_fsm.when(:stopped,
				running: :not_running,
				ready: :not_running
			)

			@_fsm.when(:died,
				running: :dead,
				ready: :dead
			)

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

			# make sure we stop on exit
			my_pid = Process.pid
			at_exit do
				stop if Process.pid == my_pid and running? #only run in master process
			end
		end

		attr_reader :name
		attr_reader :pid_file
		attr_reader :log_file
		attr_reader :ready_timeout
		attr_reader :term_timeout
		attr_reader :kill_timeout

		def reset_options(opts)
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
			@refresh_action.call(self)
			self
		end

		def restart
			puts 'restarting'
			stop
			start
		end

		def start
			return self if trigger? :stopped
			trigger? :started or fail "can't start when: #{state}"

			puts "starting: `#{@command}` log file: #{@log_file}"
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
					end

					if @kill_timeout > 0
						puts "killing process: #{@pid}"
						Process.kill("KILL", @pid)
						@process.join(@kill_timeout) and throw :done
					end
				rescue Errno::ESRCH
					throw :done
				end

				trigger :run_away
				raise ProcessRunAwayError.new(self.to_s, @pid)
			end

			trigger :stopped
			nil
		end

		def verify
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
				raise ProcessReadyTimeOutError.new(self.to_s)
			when :ready_timeout
				puts "process not ready in time; see #{log_file} for detail"
				stop
				trigger :failed
				raise ProcessReadyTimeOutError.new(self.to_s)
			else
				trigger :verified
				self
			end
		end

		def puts(message)
			super "#{name}: #{message}"
		end

		def to_s
			"#{name}[#{@command}](#{state})"
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
				log.truncate(0)

				# usefull for testing
				ENV['PROCESS_SPAWN_TYPE'] = 'exec'

				exec(@command)
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
			when Exception
				raise value
			end

			value
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
				log.truncate(0)

				# reset ARGV
				Object.instance_eval{ remove_const(:ARGV) }
				Object.const_set(:ARGV, cmd)

				# reset $0
				$0 = file

				# reset $*
				$*.replace(cmd)

				# usefull for testing
				ENV['PROCESS_SPAWN_TYPE'] = 'load'

				load file

				# make sure we exit if loaded file won't
				exit 0
			end
		end
	end
end
