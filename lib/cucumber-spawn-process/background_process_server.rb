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

				# update arguments with actual port numbers
				args = Shellwords.split(@command).map do |arg|
					arg.gsub(/<allocated port (\d)>/) do |port|
						allocated_port($1)
					end
				end
				@command = Shellwords.join(args)
			end

			def ports
				@ports
			end

			def allocated_port(port_no)
				@ports[port_no.to_i - 1] or fail "no port #{port_no} allocated: #{@ports}"
			end

			def to_s
				super + "{ports: #{ports.join(', ')}}"
			end
		end
	end
end
