require 'digest'
require 'tmpdir'
require 'pathname'
require 'rufus-lru'
require 'set'

module CucumberSpawnProcess
	class ProcessPool
		class ProcessDefinition
			def initialize(pool, name, path, type, options)
				@pool = pool
				@name = name
				@path = path
				@type = type

				@options = {
					ready_timeout: 10,
					term_timeout: 10,
					kill_timeout: 10,
					ready_test: ->(p){fail "no readiness check defined for #{p.name}"},
					refresh_action: ->(p){p.restart},
					logging: false
				}.merge(options)
				@working_directory = nil
				@arguments = []
			end

			def options(hash)
				@options.merge! hash
			end

			def working_directory(dir)
				@working_directory = dir
			end

			def arguments
				@arguments
			end

			def process
				_key = key

				# already crated
				if process = @pool[_key]
					# always make sure options are up to date with definition
					process.reset_options(@options)
					return process
				end

				return @pool[_key] ||=
					@type.new(
						"#{@name}-#{_key}",
						@path,
						@arguments,
						@working_directory || ["#{@name}-", "-#{_key}"],
						@options
					)
			end

			def key
				hash = Digest::SHA256.new
				hash.update @name
				hash.update @path
				hash.update @type.name
				hash.update @working_directory.to_s
				@arguments.each do |argument|
					case argument
					when Pathname
						begin
							# use file content as part of the hash
							hash.update argument.read
						rescue Errno::ENOENT
							# use file name if it does not exist
							hash.update argument.to_s
						end
					else
						hash.update argument.to_s
					end
				end
				Digest.hexencode(hash.digest)[0..16]
			end
		end

		class LRUPool < Hash
			class VoidHash < Hash
				def []=(key, value)
					value
				end
			end

			def initialize(max_running, &lru_stop)
				@running_keep = max_running > 0 ? LruHash.new(max_running) : VoidHash.new
				@running_all = Set.new
				@active = Set.new

				@after_store = []
				@lru_stop = lru_stop
			end

			def []=(key, value)
				@active << key
				super
				@after_store.each{|callback| callback.call(key, value)}
			end

			def [](key)
				if self.member? key
					@active << key
					@running_keep[key] # bump on use if on running LRU list
				end
				super
			end

			def delete(key)
				@running_keep.delete(key)
				@running_all.delete(key)
				@active.delete(key)
				super
			end

			def reset_active
				@active = Set.new
				trim!
			end

			def running(key)
				return unless member? key
				@running_keep[key] = key
				@running_all << key
				trim!
			end

			def not_running(key)
				@running_keep.delete(key)
				@running_all.delete(key)
			end

			def after_store(&callback)
				@after_store << callback
			end

			private

			def trim!
				to_stop.each do |key|
					@lru_stop.call(key, self[key])
				end
			end

			def to_stop
				@running_all - @active - @running_keep.values
			end
		end

		def initialize(options)
			@definitions = {}
			@stats = {}

			@max_running = options.delete(:max_running) || 4

			@pool = LRUPool.new(@max_running) do |key, process|
				#puts "too many processes running, stopping: #{process.name}"
				stats(process.name)[:lru_stopped] += 1
				process.stop
			end

			# keep track of running running
			@pool.after_store do |key, process|
				process.after_state_change do |new_state|
					# we mark running before it is actually started to have a chance to stop over-limit process first
					if new_state == :starting
						@pool.running(key)
						stats(process.name)[:started] += 1
					end
					@pool.not_running(key) if [:not_running, :dead, :jammed].include? new_state
				end

				# mark running if added while already running
				@pool.running(key) if process.running?

				# init stats
				stats(process.name)[:started] ||= 0
				stats(process.name)[:lru_stopped] ||= 0
			end

			# this are passed down to processes
			@options = options
		end

		def define(name, path, type)
			@definitions[name] = ProcessDefinition.new(@pool, name, path, type, @options)
		end

		def [](name)
			@definitions[name] or fail "process #{name} not defined"
		end

		def reset_active
			@pool.reset_active
		end

		def stats(name)
			@stats[name] ||= {}
		end

		def report_stats
			puts
			puts "Process pool stats:"
			@stats.each do |key, stats|
				puts "#{key}: #{stats.map{|k, v| "#{k}: #{v}"}.join(' ')}"
			end
		end

		def failed_process
			@pool.values.select do |process|
				process.dead? or
				process.failed? or
				process.jammed?
			end.sort_by do |process|
				process.state_change_time
			end.last
		end
	end
end
