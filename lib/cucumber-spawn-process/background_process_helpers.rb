require_relative 'background_process'
require_relative 'process_pool'

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
end
