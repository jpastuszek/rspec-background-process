require 'digest'
require 'tmpdir'

module CucumberSpawnProcess
	class ProcessPool
		def initialize
			@definitions = {}
			@processes = {}
		end

		def define(name, path, type)
			fail "process #{name} already defined (#{@definitions[name]})" if @definitions.member? name and @definitions[name].values_at(:path, :type) != [path, type]
			@definitions[name] = {path: path, type: type, options: {}}
		end

		def options(name, hash)
			fail "process #{name} not defined or definition already used" unless @definitions.member? name
			@definitions[name][:options].merge! hash
		end

		def get(name, arguments)
			key = self.class.key(name, arguments)
			@processes[key] and return @processes[key]

			definition = @definitions[name] or fail "process #{name} not defined"
			@processes[key] ||= definition[:type].new("#{name}-#{key}", definition[:path], arguments, Dir.mktmpdir("#{name}-#{key}"), definition[:options])
			@definitions.delete(name)
			@processes[key]
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
