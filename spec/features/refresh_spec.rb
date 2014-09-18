require_relative '../spec_helper'

feature 'refreshing pooled processes state', subject: :process do
	scenario 'by default processes are restarted on refresh' do
		instance = subject.start
		pid = instance.pid

		instance.refresh
		expect(instance.pid).not_to eq pid
	end

	context 'with custom command' do
		let! :test_marker do
			Pathname.new('/tmp/processtest1')
		end

		before do
			test_marker.exist? and test_marker.unlink
		end

		scenario 'refresh executes custom command' do
			instance = subject.with do |process|
				process.refresh_command "touch #{test_marker}"
			end.start

			expect(test_marker).not_to exist

			instance.refresh

			expect(test_marker).to exist
		end

		scenario 'refresh execute command in current working directory of the process' do
			instance = subject.with do |process|
				process.refresh_command "pwd > /tmp/pwd"
			end.start

			instance.refresh

			expect(Pathname.new(Pathname.new('/tmp/pwd').read.strip).realpath.to_s).to eq instance.working_directory.realpath.to_s
		end
	end
end

