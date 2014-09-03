require 'digest'
require 'tmpdir'

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
				}
			}
		end

		def options(name, hash)
			fail "process #{name} not defined" unless @definitions.member? name
			@definitions[name][:options].merge! hash
		end

		def get(name, arguments)
			key = self.class.key(name, arguments)

			# already crated
			if process = @processes[key]
				# always make sure options are up to date with definition
				process.reset_options(@definitions[name][:options])
				return process
			end

			definition = @definitions[name] or fail "process #{name} not defined"

			return @processes[key] ||=
			definition[:type].new(
				"#{name}-#{key}",
				definition[:path],
				arguments,
				Dir.mktmpdir("#{name}-#{key}"),
				definition[:options]
			)
		end

		def self.key(name, arguments)
			hash = Digest::SHA256.new
			hash.update name
			arguments.each do |argument|
				case argument
				when Pathname
					hash.update argument.read
				else
					hash.update argument.to_s
				end
			end
			Digest.hexencode(hash.digest)[0..16]
		end
	end
end
