require 'open-uri'
require 'file-tail'
require 'retries'

require_relative 'process_pool'

module CucumberSpawnProcess
	class ProcessPool
		class ProcessDefinition
			def ready_when_log_includes(log_line)
				ready_test do |instance|
					log_line = instance.render(log_line)

					# NOTE: log file my not be crated just after process is started (spawned) so we need to retry
					with_retries(
						max_tries: 10000,
						base_sleep_seconds: 0.01,
						max_sleep_seconds: 0.2,
						rescue: Errno::ENOENT
					) do
						File::Tail::Logfile.tail(instance.log_file, forward: 0, interval: 0.01, max_interval: 1, suspicious_interval: 4) do |line|
							line.include?(log_line) and break true
						end
					end
				end
			end

			def ready_when_url_response_status(uri, status = 'OK')
				ready_test do |instance|
					_uri = instance.render(uri) # NOTE: new variable (_uri) is needed or strange things happen...

					begin
						with_retries(
						max_tries: 10000,
						base_sleep_seconds: 0.06,
						max_sleep_seconds: 0.2,
						rescue: Errno::ECONNREFUSED
						) do
							open(_uri).status.last.strip == status and break true
						end
					end
				end
			end
		end
	end
end


