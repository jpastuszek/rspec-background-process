require_relative '../spec_helper'

feature 'background process is marked as dead if it exits before stop was called', subject: :dying_process do
	scenario 'running dieing process renders it marked as dead' do
		instance = subject.start
		expect(instance).not_to be_dead

		# git it some time to spawn and exit
		sleep 0.5
		expect(instance).to be_dead
	end
end

feature 'dead instance should not be usable any more', subject: :dying_process do
	scenario 'trying to #start dead instance' do
		instance = subject.start

		# git it some time to spawn and exit
		sleep 0.5

		expect {
			instance.start
		}.to raise_error CucumberSpawnProcess::BackgroundProcess::StateError, /can't start when in state: dead/
	end

	scenario 'trying to #stop or #restart dead instance' do
		instance = subject.start

		# git it some time to spawn and exit
		sleep 0.5

		expect {
			instance.stop
		}.to raise_error CucumberSpawnProcess::BackgroundProcess::StateError, /can't stop when in state: dead/

		expect {
			instance.restart
		}.to raise_error CucumberSpawnProcess::BackgroundProcess::StateError, /can't stop when in state: dead/
	end

	scenario 'trying to #wait_ready on dead instance' do
		instance = subject.start

		# git it some time to spawn and exit
		sleep 0.5

		expect {
			instance.wait_ready
		}.to raise_error CucumberSpawnProcess::BackgroundProcess::StateError, /can't wait ready when in state: dead/
	end
end

feature 'detecting instance death wile waiting for it to become ready', subject: :slowly_dying_process do
	context 'with log file based check' do
		scenario 'instance dying while we wait for it to become ready' do
			subject.ready_when_log_includes 'bye'

			instance = subject.start

			expect {
				instance.wait_ready
			}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessExitedError, /exited with exit code: 0/

			expect(instance).to be_dead
		end
	end

	context 'with URL based check' do
		scenario 'instance dying while we wait for it to become ready' do
			subject.ready_when_url_response_status 'http://localhost:1234/health_check', 'OK'

			instance = subject.start

			expect {
				instance.wait_ready
			}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessExitedError, /exited with exit code: 0/

			expect(instance).to be_dead
		end
	end
end
