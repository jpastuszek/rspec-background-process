$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rspec-background-process'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'rspec/core/shared_context'

module Process
	extend RSpec::Core::SharedContext

	subject do
		background_process('spec/support/test_process', group: "fresh[#{rand}]", load: true)
	end
end

module ProcessWithLoggedVariables
	extend RSpec::Core::SharedContext

	subject do
		background_process('spec/support/test_process', group: "fresh[#{rand}]", load: true).with do |process|
			process.ready_when_log_includes 'hello world'
		end
	end
end

module Instance
	extend RSpec::Core::SharedContext

	subject do
		background_process('spec/support/test_process', group: "fresh[#{rand}]", load: true).instance
	end
end

module HTTPProcessWithLoggedVariables
	extend RSpec::Core::SharedContext

	subject do
		background_process('spec/support/test_http_server', group: "http_fresh[#{rand}]", load: true).with do |process|
			process.ready_when_log_includes 'listening'
		end
	end
end

module HTTPProcess
	extend RSpec::Core::SharedContext

	subject do
		background_process('spec/support/test_http_server', group: "http_fresh[#{rand}]", load: true)
	end
end

module DyingProcess
	extend RSpec::Core::SharedContext

	subject do
		background_process('spec/support/test_die', group: "die[#{rand}]", load: true)
	end
end

module SlowlyDyingProcess
	extend RSpec::Core::SharedContext

	subject do
		background_process('spec/support/test_slow_die', group: "slow_die[#{rand}]", load: true)
	end
end

RSpec::Matchers.define_negated_matcher :different_than, :be

RSpec.configure do |config|
	config.include Process, subject: :process
	config.include SpawnProcessHelpers, subject: :process

	config.include ProcessWithLoggedVariables, subject: :process_ready_variables
	config.include SpawnProcessHelpers, subject: :process_ready_variables

	config.include Instance, subject: :instance
	config.include SpawnProcessHelpers, subject: :instance

	config.include HTTPProcess, subject: :http_process
	config.include SpawnProcessHelpers, subject: :http_process

	config.include HTTPProcessWithLoggedVariables, subject: :http_process_ready_variables
	config.include SpawnProcessHelpers, subject: :http_process_ready_variables

	config.include DyingProcess, subject: :dying_process
	config.include SpawnProcessHelpers, subject: :dying_process

	config.include SlowlyDyingProcess, subject: :slowly_dying_process
	config.include SpawnProcessHelpers, subject: :slowly_dying_process

	config.alias_example_group_to :feature
	config.alias_example_to :scenario

	config.before :all do
		#process_pool(logging: true)
	end
end
