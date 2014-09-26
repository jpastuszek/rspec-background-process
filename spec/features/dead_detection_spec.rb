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
		}.to raise_error CucumberSpawnProcess::BackgroundProcess::StateError, "can't start when: dead"
	end

	scenario 'trying to #stop or #restart dead instance' do
		instance = subject.start

		# git it some time to spawn and exit
		sleep 0.5

		expect {
			instance.stop
		}.to raise_error CucumberSpawnProcess::BackgroundProcess::StateError, "can't stop when: dead"

		expect {
			instance.restart
		}.to raise_error CucumberSpawnProcess::BackgroundProcess::StateError, "can't stop when: dead"
	end

	scenario 'trying to #wait_ready on dead instance' do
		instance = subject.start

		# git it some time to spawn and exit
		sleep 0.5

		expect {
			instance.wait_ready
		}.to raise_error CucumberSpawnProcess::BackgroundProcess::StateError, "can't wait ready when: dead"
	end
end
