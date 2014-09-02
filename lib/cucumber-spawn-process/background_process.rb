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
			@cmd = cmd
			@args = args

			@pid = nil
			@process = nil

			@working_directory = Pathname.new working_directory
			@working_directory.directory? or @working_directory.mkdir

			@pid_file = @working_directory + "#{@name}.pid"
			@log_file = @working_directory + "#{@name}.log"

			@ready_test = ->(_){true}
			@refresh = ->(_){restart}

			@ready_timeout = options[:ready_timeout] || 10
			@term_timeout = options[:term_timeout] || 10
			@kill_timeout = options[:kill_timeout] || 10

			@fsm = MicroMachine.new(:not_running)
			@fsm.on(:any) do
				puts "current state: #{@fsm.state}"
			end

			@fsm.when(:started,
				not_running: :running
			)
			@fsm.on(:running) do
				puts "running with pid: #{@pid}, log file: #{@log_file}"
			end

			@fsm.when(:stopped,
				running: :not_running,
				ready: :not_running,
			)

			@fsm.when(:died,
				running: :not_running,
				ready: :not_running
			)

			@fsm.when(:verified,
				running: :ready,
				ready: :ready,
			)
			@fsm.when(:run_away,
				running: :jammed,
				ready: :jammed
			)

			# make sure we stop on exit
			my_pid = Process.pid
			at_exit do
				stop if Process.pid == my_pid #only run in master process
			end
		end

		attr_reader :name
		attr_reader :pid_file
		attr_reader :log_file
		attr_accessor :ready_timeout

		def command
			Shellwords.join([@cmd, *@args])
		end

		def pid
			return nil unless running?
			@pid
		end

		def exit_code
			return nil if not @process
			return nil if running?
			@process.value.exitstatus
		end

		def running?
			@fsm.trigger? :stopped # if it can be stopped it must be running :D
		end

		def ready?
			@fsm.state == :ready
		end

		def state
			@fsm.state
		end

		def ready_when(&block)
			@ready = false
			@ready_test = block
		end

		def refresh
			puts 'refreshing'
			@refresh.call(self)
			self
		end

		def restart
			puts 'restarting'
			stop
			start
		end

		def start
			return self if @fsm.trigger? :stopped
			@fsm.trigger? :started or fail "can't start when: #{@fsm.state}"

			puts 'starting'
			@pid, @process = spawn
			@fsm.trigger :started
			self
		end

		def verify
			@fsm.trigger? :verified or fail "can't verify when: #{@fsm.state}"

			puts 'verifying'

			status = while_running do
				begin
					Timeout.timeout(@ready_timeout) do
						loop do
							break if @ready_test.call(self)
							sleep 0.1
						end
					end
				rescue Timeout::Error
					:ready_timeout
				else
					:ready
				end
			end

			if status == :ready_timeout
				puts "failed to start in time; see #{log_file} for detail"
				stop
				raise ProcessReadyTimeOutError.new(self.to_s)
			end

			@fsm.trigger :verified
			self
		end

		def stop
			return if @fsm.trigger? :started
			@fsm.trigger? :stopped or fail "can't stop while: #{@fsm.state}"

			catch :done do
				begin
					puts "stopping process: #{@pid}"
					Process.kill("TERM", @pid)
					@process.join(@term_timeout) and throw :done

					puts "killing process: #{@pid}"
					Process.kill("KILL", @pid)
					@process.join(@kill_timeout) and throw :done
				rescue Errno::ESRCH
					throw :done
				end

				@fsm.trigger :run_away
				raise ProcessRunAwayError.new(self.to_s, @pid)
			end

			@fsm.trigger :stopped
			nil
		end

		def puts(message)
			super "#{name}: #{message}"
		end

		def to_s
			"#{name}[#{command}](#{state})"
		end

		private

		def spawn
			Daemon.daemonize(@pid_file, @log_file) do |log|
				log.truncate(0)
				exec(command)
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
				@fsm.trigger :died
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
			cmd = Shellwords.split(command)
			file = cmd.shift

			puts "loading ruby script: #{file}"
			Daemon.daemonize(@pid_file, @log_file) do |log|
				log.truncate(0)
				ENV['ARGV'] = Shellwords.join(cmd)
				load file
			end
		end
	end
end
