require 'rspec'
require 'rspec/core/formatters'
require 'rspec/core/shared_context'
require_relative 'background_process'
require_relative 'process_pool'

# config.include SpawnProcessHelpers
module SpawnProcessHelpers
	extend RSpec::Core::SharedContext

	def process_pool(options = {})
		@@process_pool ||= CucumberSpawnProcess::ProcessPool.new(options)
	end

	def background_process(path, options = {})
		CucumberSpawnProcess::ProcessPool::ProcessDefinition.new(
			process_pool.pool,
			options[:group] || 'default',
			path,
			options[:load] ? CucumberSpawnProcess::LoadedBackgroundProcess : CucumberSpawnProcess::BackgroundProcess,
			process_pool.options
		)
	end

	def self.report_failed_instance
		return unless defined? @@process_pool

		@@process_pool.report_failed_instance
		@@process_pool.report_logs
	end

	after(:each) do
		@@process_pool.reset_active
	end
end

# config.add_formatter FailedInstanceReporter
class FailedInstanceReporter
	RSpec::Core::Formatters.register self, :example_failed

	def initialize(output)
		@output = output
	end

	def example_failed(example)
		@output << SpawnProcessHelpers.report_failed_instance
	end
end

