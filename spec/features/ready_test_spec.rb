require_relative '../spec_helper'

feature 'background process readiness verification' do
	context 'with log file based check', subject: :process do
		scenario 'raise exception when no readiness check was defined for process instance' do
			expect {
				subject.start.verify
			}.to raise_error RuntimeError, 'no readiness check defined'
		end

		scenario 'starting a background process with readiness check based on log file contents' do
			process = subject.with do |process|
				process.ready_when_log_includes 'started'
			end

			instance = process.instance
			instance.start.verify

			expect(instance).to be_running
			expect(instance).to be_ready
		end
	end

	context 'with URL based check', subject: :http_process do
		scenario 'starting a background process with readiness check based on HTTP request' do
			process = subject.with do |process|
				process.ready_when_url_response_status 'http://localhost:1234/health_check', 'OK'
			end

			instance = process.instance
			instance.start.verify

			expect(instance).to be_running
			expect(instance).to be_ready
		end
	end
end

