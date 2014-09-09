require 'digest'
require 'tmpdir'
require 'pathname'
require 'rufus-lru'
require 'set'
require 'delegate'

module CucumberSpawnProcess
	class ProcessPool
		class ProcessDefinition
			def initialize(pool, name, path, type, options)
				@pool = pool
				@name = name
				@path = path
				@type = type

				@extensions = Set.new
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

			attr_reader :name

			def extend(mod, options)
				@extensions << mod
				@options.merge! options
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

			def instance
				# disallow changes to the definition once we have instantiated
				@options.freeze
				@arguments.freeze
				@working_directory.freeze
				@extensions.freeze

				# instance is requested
				# we calculate key based on current definition
				_key = key

				# already crated
				if instance = @pool[_key]
					# always make sure options are up to date with definition
					instance.reset_options(@options)
					return instance
				end

				# need to crate new one
				instance = @type.new(
					@name,
					@path,
					@arguments,
					@working_directory || ["#{@name}-", "-#{_key}"],
					@options
				)

				# ports get allocated here...
				@extensions.each do |mod|
					instance.extend(mod)
				end

				@pool[_key] = instance
			end

			def key
				hash = Digest::SHA256.new
				hash.update @name
				hash.update @path
				hash.update @type.name
				@extensions.each do |mod|
					hash.update mod.name
				end
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
				@running_all = Set[]
				@active = Set[]

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
			reset_definitions
			@stats = {}

			@max_running = options.delete(:max_running) || 4

			@pool = LRUPool.new(@max_running) do |key, instance|
				#puts "too many instances running, stopping: #{instance.name}"
				stats(instance.name)[:lru_stopped] += 1
				instance.stop
			end

			# keep track of running instances
			@pool.after_store do |key, instance|
				instance.after_state_change do |new_state|
					# we mark running before it is actually started to have a chance to stop over-limit instance first
					if new_state == :starting
						@pool.running(key)
						stats(instance.name)[:started] += 1
					end
					@pool.not_running(key) if [:not_running, :dead, :jammed].include? new_state
				end

				# mark running if added while already running
				@pool.running(key) if instance.running?

				# init stats
				stats(instance.name)[:started] ||= 0
				stats(instance.name)[:lru_stopped] ||= 0
			end

			# for storing shared data
			@global_context = {}

			# for filling template strings with actual instance data
			@template_renderer = ->(variables, string) {
				out = string.dup
				variables.merge(
					/project directory/ => -> { Dir.pwd.to_s }
				).each do |regexp, source|
					out.gsub!(/<#{regexp}>/) do
						source.call(*$~.captures)
					end
				end
				out
			}

			# this are passed down to instance
			@options = options.merge(
				global_context:  @global_context,
				template_renderer: @template_renderer
			)
		end

		def define(name, path, type)
			@definitions.member? name and fail "redefining background process '#{name}' is not allowed"
			@definitions[name] = ProcessDefinition.new(@pool, name, path, type, @options)
		end

		def [](name)
			@definitions[name] or fail "process #{name} not defined"
		end

		def reset_definitions
			@definitions = {}
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

		def failed_instance
			@pool.values.select do |instance|
				instance.dead? or
				instance.failed? or
				instance.jammed?
			end.sort_by do |instance|
				instance.state_change_time
			end.last
		end
	end
end
