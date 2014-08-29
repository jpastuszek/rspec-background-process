require 'digest'
require 'tmpdir'

module CucumberSpawnProcess
	class ProcessPool
		def initialize
			@definitions = {}
			@processes = {}
		end

		def define(name, path, type)
			fail "process #{name} already defined (#{@definitions[name]})" if @definitions.member? name and @definitions[name] != {path: path, type: type}
			@definitions[name] = {path: path, type: type}
		end

		def get(name, arguments)
			definition = @definitions[name] or fail "process #{name} not defined"
			key = self.class.key(name, arguments)
			@processes[key] ||= definition[:type].new("#{name}-#{key}", definition[:path], arguments, Dir.mktmpdir("#{name}-#{key}"))
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
