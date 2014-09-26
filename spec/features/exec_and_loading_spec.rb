require_relative '../spec_helper'

feature 'support for starting new process via fort to exec or fork followed by Ruby load' do
	context 'default value is used' do
		scenario 'replace forked ruby interpreter with given executable via exec' do
			process = background_process('spec/support/test_process')

			process.ready_when_log_includes "ENV['PROCESS_SPAWN_TYPE']"
			instance = process.start.wait_ready

			expect(instance.log_file.read).to include "ENV['PROCESS_SPAWN_TYPE']: exec"
		end
	end

	context 'load is set to true' do
		scenario 'load ruby code directly into forked interpreter via load' do
			process = background_process('spec/support/test_process', load: true)

			process.ready_when_log_includes "ENV['PROCESS_SPAWN_TYPE']"
			instance = process.start.wait_ready

			expect(instance.log_file.read).to include "ENV['PROCESS_SPAWN_TYPE']: load"
		end
	end
end

