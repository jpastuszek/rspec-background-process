require_relative 'process_pool'

module RSpecBackgroundProcess
	class ProcessPool
		class ProcessDefinition
			def refresh_command(command)
				refresh_action do |instance|
					_command = instance.render(command)
					system _command
				end
			end
		end
	end
end

