require_relative '../spec_helper'

feature 'background process readiness verification' do
	scenario 'raise exception when no readiness check was defined for process instance' do
		process = background_process('features/support/test_process', load: true, group: 'ready1')
		instance = process.instance
		expect {
			instance.start.verify
		}.to raise_error RuntimeError, 'no readiness check defined'
	end

	scenario 'starting a background process with readiness check based on log file contents' do
		process = background_process('features/support/test_process', load: true, group: 'ready2').with do
			ready_when_log_includes 'started'
		end

		instance = process.instance
		instance.start.verify

		expect(instance).to be_running
		expect(instance).to be_ready
	end

	scenario 'starting a background process with readiness check based on HTTP request' do
		process = background_process('features/support/test_http_server', load: true, group: 'ready3').with do
			ready_when_url_response_status 'http://localhost:1234/health_check', 'OK'
		end

		instance = process.instance
		instance.start.verify

		expect(instance).to be_running
		expect(instance).to be_ready
	end
end

