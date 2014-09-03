require 'digest'
require 'tmpdir'
require 'pathname'

module CucumberSpawnProcess
	class ProcessPool
		def initialize
			@definitions = {}
			@processes = {}
		end

		def define(name, path, type)
			fail "cannot change #{name} process path or type (#{@definitions[name]})" if @definitions.member? name and @definitions[name].values_at(:path, :type) != [path, type]

			@definitions[name] = {
				path: path,
				type: type,
				# set default options
				options: {
					ready_timeout: 10,
					term_timeout: 10,
					kill_timeout: 10,
					ready_test: ->(p){fail "no readiness check defined for #{p.name}"},
					refresh_action: ->(p){p.restart}
				},
				working_directory: nil, # use mktemp(name + key) dir
				arguments: []
			}
		end

		def options(name, hash)
			fail "process #{name} not defined" unless @definitions.member? name
			@definitions[name][:options].merge! hash
		end

		def working_directory(name, dir)
			fail "process #{name} not defined" unless @definitions.member? name
			@definitions[name][:working_directory] = dir
		end

		def arguments(name)
			fail "process #{name} not defined" unless @definitions.member? name
			@definitions[name][:arguments]
		end

		def get(name)
			definition = @definitions[name] or fail "process #{name} not defined"

			key = self.class.key(name, definition[:working_directory], definition[:arguments])

			# already crated
			if process = @processes[key]
				# always make sure options are up to date with definition
				process.reset_options(@definitions[name][:options])
				return process
			end

			return @processes[key] ||=
			definition[:type].new(
				"#{name}-#{key}",
				definition[:path],
				definition[:arguments],
				definition[:working_directory] || ["#{name}-", "-#{key}"],
				definition[:options]
			)
		end

		private

		def self.key(name, working_directory, arguments)
			hash = Digest::SHA256.new
			hash.update name
			hash.update working_directory.to_s
			arguments.each do |argument|
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
end
