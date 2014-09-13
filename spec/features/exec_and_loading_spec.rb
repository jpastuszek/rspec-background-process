require_relative '../spec_helper'

feature 'loading ruby scrip or executing process after fork' do
	context 'default value is used' do
		scenario 'replace forked ruby interpreter with given executable via exec' do
			process = background_process('features/support/test_process')
			instance = process.start
			sleep 1 # TODO: use ready check
			expect(instance.log_file.read).to include "ENV['PROCESS_SPAWN_TYPE']: exec"
		end
	end

	context 'load is set to true' do
		scenario 'load ruby code directly into forked interpreter via load' do
			process = background_process('features/support/test_process', load: true)
			instance = process.start
			sleep 1 # TODO: use ready check
			expect(instance.log_file.read).to include "ENV['PROCESS_SPAWN_TYPE']: load"
		end
	end
end

