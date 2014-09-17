require_relative '../spec_helper'

feature 'refreshing pooled processes state', subject: :process do
	scenario 'by default processes are restarted on refresh' do
		instance = subject.start
		pid = instance.pid

		instance.refresh
		expect(instance.pid).not_to eq pid
	end

	let! :test_marker do
		Pathname.new('/tmp/processtest1')
	end

	scenario 'by custom command' do
		command = "touch #{test_marker}" # for scoping

		instance = subject.with do
			refresh_command command
		end.start

		expect(test_marker).not_to exist

		instance.refresh

		expect(test_marker).to exist
	end
end

