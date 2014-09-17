require_relative 'background_process'
require_relative 'process_pool'

# config.include SpawnProcessHelpers
module SpawnProcessHelpers
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
		@@process_pool.report_failed_instance if @@process_pool
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

