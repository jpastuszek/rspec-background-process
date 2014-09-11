$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cucumber-spawn-process'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'rspec/core/shared_context'

module FreshProcess
	extend RSpec::Core::SharedContext

	subject! do
		background_process('features/support/test_process', group: "fresh[#{rand}]")
	end

	def instance
		subject.instance
	end
end

module SharedProcess
	extend RSpec::Core::SharedContext

	subject do
		background_process('features/support/test_process')
	end

	def instance
		subject.instance
	end
end

module SharedInstance
	extend RSpec::Core::SharedContext

	subject do
		background_process('features/support/test_process').instance
	end
end

RSpec.configure do |config|
	config.include SpawnProcessHelpers
	config.include FreshProcess, subject: :fresh_process
	config.include SharedProcess, subject: :shared_process
	config.include SharedInstance, subject: :shared_instance

	config.before :all do
		#process_pool(logging: true)
	end
end
