module CucumberSpawnProcess
	class BackgroundProcess
		module Server
			def self.extended(mod)
				mod.allocate_ports
			end

			def allocate_ports
				base_port = @options[:base_port] or fail "no base_port option set for #{self}: #{@options}"
				port_count = @options[:port_count] or fail "no port_count option set for #{self}: #{@options}"

				global_ports = @options[:global_context][:ports] ||= Set[]

				begin
					@ports = (base_port ... base_port + port_count).to_a
					base_port += port_count
				end until (global_ports & @ports).empty?

				@options[:global_context][:ports] = global_ports + @ports
			end

			def ports
				@ports
			end

			def to_s
				super + "{ports: #{ports.join(', ')}}"
			end
		end
	end
end