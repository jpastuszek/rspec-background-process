require 'digest'
require 'tmpdir'
require 'pathname'

module CucumberSpawnProcess
	class ProcessPool
		class ProcessDefinition
			def initialize(pool, name, path, type)
				@pool = pool
				@name = name
				@path = path
				@type = type

				@options = {
					ready_timeout: 10,
					term_timeout: 10,
					kill_timeout: 10,
					ready_test: ->(p){fail "no readiness check defined for #{p.name}"},
					refresh_action: ->(p){p.restart}
				}
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

		def initialize
			@definitions = {}
			@pool = {}
		end

		def define(name, path, type)
			@definitions[name] = ProcessDefinition.new(@pool, name, path, type)
		end

		def [](name)
			@definitions[name] or fail "process #{name} not defined"
		end
	end
end
