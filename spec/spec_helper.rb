$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cucumber-spawn-process'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'rspec/core/shared_context'

module Process
	extend RSpec::Core::SharedContext

	subject! do
		background_process('features/support/test_process', group: "fresh[#{rand}]", load: true)
	end
end

module Instance
	extend RSpec::Core::SharedContext

	subject! do
		background_process('features/support/test_process', group: "fresh[#{rand}]", load: true).instance
	end
end

RSpec::Matchers.define_negated_matcher :different_than, :be

RSpec.configure do |config|
	config.include SpawnProcessHelpers
	config.include Process, subject: :process
	config.include Instance, subject: :instance

	config.alias_example_group_to :feature
	config.alias_example_to :scenario

	config.before :all do
		#process_pool(logging: true)
	end
end
