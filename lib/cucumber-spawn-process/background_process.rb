require 'pathname'
require 'tmpdir'
require 'daemon'
require 'shellwords'

module CucumberSpawnProcess
	class BackgroundProcess
		def initialize(name, cmd, args = [], working_directory = Dir.mktmpdir(name))
			@name = name
			@cmd = cmd
			@args = args

			@pid = nil
			@wait = nil

			@working_directory = Pathname.new working_directory
			@working_directory.directory? or @working_directory.mkdir

			@pid_file = @working_directory + "#{@name}.pid"
			@log_file = @working_directory + "#{@name}.log"

			@ready = ->(_){true}
			@refresh = ->(_){restart}

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
		attr_accessor :ready_timeout

		def command
			Shellwords.join([@cmd, *@args])
		end

		def pid
			alive? and @pid
		end

		def alive?
			return false unless @wait
			@wait.alive?
		end

		def ready?
			@ready.call(self)
		end

		def ready_when(&block)
			@ready = block
		end

		def refresh
			puts 'refreshing'
			@refresh.call(self)
			if not ready?
				puts 'not working after refresh: restarting'
				start
			end
		end

		def restart
			puts 'restarting'
			stop
			start
		end

		def spawn
			Daemon.daemonize(@pid_file, @log_file) do |log|
				log.truncate(0)
				exec(command)
			end
		end

		def start
			return if alive? and ready? # already there

			puts 'starting'
			@pid, @wait = spawn
			puts "#{self} started with pid: #{@pid}; log file: #{@log_file}"

			Timeout.timeout(@ready_timeout) do
				loop do
					alive? or fail "#{self} process #{@pid} died"
					ready? and break
					sleep 0.1
				end
			end

			return pid
		rescue Timeout::Error
			puts "failed to start in time (timeout); see #{log_file} for detail"
			raise
		end

		def stop
			return unless @pid and @wait # need pid to do anything useful here
			return unless alive?

			puts 'stopping'

			begin
				Process.kill("TERM", @pid)
				# TODO: configurable time out
				thr = @wait.join(10) and return thr.value

				puts "killing process: #{@pid}"
				Process.kill("KILL", @pid)
				thr = @wait.join(10) and return thr.value

				fail "cannot kill process: #{@pid}"
			rescue Errno::ESRCH
				# already gone
				return thr.value
			ensure
				pid_file.unlink
				@pid = nil
				@wait = nil
			end
		end

		def puts(message)
			super "#{name}: #{message}"
		end

		def to_s
			"#{name}[#{command}]"
		end
	end

	class LoadedBackgroundProcess < BackgroundProcess
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
