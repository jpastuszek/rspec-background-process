require 'pathname'
require 'tmpdir'
require 'daemon'
require 'shellwords'

module CucumberSpawnProcess
	class BackgroundProcess
		# When included the cmd will be loaded in forked ruby interpreter and arguments passed via ENV['ARGS']
		# This way starting new process will be much faster since ruby VM is already loaded
		module Loading
			def spawn
				fork do
					Daemon.daemonize(pid_file, log_file)
					cmd = Shellwords.split(command)
					file = cmd.shift
					ENV['ARGS'] = Shellwords.join(cmd)
					load file
				end
			end
		end

		def initialize(name, cmd, args = [], working_directory = Dir.mktmpdir(name))
			@name = name
			@cmd = cmd
			@args = args

			@working_directory = Pathname.new working_directory
			@working_directory.directory? or @working_directory.mkdir

			@pid_file = @working_directory + "#{@name}.pid"
			@log_file = @working_directory + "#{@name}.log"

			@ready = ->(_){true}
			@refresh = ->{restart}

			# TODO: parametrize
			@ready_timeout = 10

			# make sure we stop on exit
			my_pid = Process.pid
			at_exit do
				stop if Process.pid == my_pid #only run in master process
			end
		end

		attr_reader :name
		attr_reader :pid_file
		attr_reader :log_file
		attr_reader :ready_timeout

		def pid_file?
			pid_file.file?
		end

		def log_file?
			log_file.file?
		end

		def pid
			return nil unless pid_file.exist?
			pid_file.read.strip.to_i
		end

		def command
			Shellwords.join([@cmd, *@args])
		end

		def ready?
			@ready.call(self)
		end

		def ready_when(&block)
			@ready = block
		end

		def refresh
			puts "refreshing"
			@refresh and @refresh.call(self)
			if not ready?
				puts "not working after refresh: restarting"
				start
			end
		end

		def restart
			puts "restarting"
			stop
			start
		end

		def spawn
			fork do
				Daemon.daemonize(pid_file, log_file)
				exec(command)
			end
		end

		def start
			puts "starting"
			return if pid_file? and ready?

			spawn

			ppid, _ = Process.wait
			Timeout.timeout(4) do
				sleep 0.1 until pid_file?
			end

			puts "#{self} started with pid: #{ppid}; log file: #{log_file}"

			### Note that the process is disconnected so kill(0,) or wait(pid) won't work
			### Also pid_file may not exist yet or may not be locked yet
			### The only option is to wait for user provided ready? to return true
			Timeout.timeout(@ready_timeout) do
				sleep 0.1 until ready?
			end
		rescue Errno::ESRCH
			puts "exited; see #{log_file} for detail"
			raise
		rescue Timeout::Error
			puts "failed to start in time (timeout); see #{log_file} for detail"
			raise
		end

		def stop
			puts 'stopping'
			return unless pid # need pid to do anything useful here

			Timeout.timeout(20) do
				begin
					begin
						Timeout.timeout(15) do
							loop do
								Process.kill("TERM", pid)
								sleep 0.1
							end
						end
					rescue Timeout::Error
						loop do
							puts "killing process: #{pid}"
							Process.kill("KILL", pid)
							sleep 0.2
						end
					end
				rescue Errno::ESRCH
					pid_file.unlink
				end
			end
		end

		def puts(message)
			super "#{name}: #{message}"
		end

		def to_s
			"#{name}[#{command}]"
		end
	end
end
