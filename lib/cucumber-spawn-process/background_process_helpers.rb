require 'rspec'
require 'rspec/core/formatters'
require 'rspec/core/shared_context'
require_relative 'background_process'
require_relative 'process_pool'

# Just methods
# config.include SpawnProcessCoreHelpers
module SpawnProcessCoreHelpers
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

	def self.report_pool_stats
		return unless defined? @@process_pool

		@@process_pool.report_stats
	end
end

# RSpec specific cleanup
# config.include SpawnProcessHelpers
module SpawnProcessHelpers
	extend RSpec::Core::SharedContext
	include SpawnProcessCoreHelpers

	after(:each) do
		@@process_pool.cleanup
	end
end

# RSpec custom reporter
# config.add_formatter FailedInstanceReporter
class FailedInstanceReporter
	RSpec::Core::Formatters.register self, :example_failed

	def initialize(output)
		@output = output
	end

	def example_failed(example)
		@output << SpawnProcessCoreHelpers.report_failed_instance
	end
end

# Cucumber setup
if respond_to?(:World) and respond_to?(:After)
	World(SpawnProcessCoreHelpers)

	After do
		process_pool.cleanup
	end

	After do |scenario|
		if scenario.failed?
			SpawnProcessCoreHelpers.report_failed_instance
		end
	end
end

## To configure pool in Cucumber add this to env.rb
# Before do
#   process_pool(
#     logging: true,
#     max_running: 16
#   )
# end

## To report pool/LRU statistics at exit add this to env.rb
# at_exit do
#   SpawnProcessCoreHelpers.report_pool_stats
# end
