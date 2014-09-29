require_relative '../spec_helper'

feature 'server process with port allocation', subject: :http_process do
	scenario 'allocating port for new process instance form pool' do
		instance = subject.with do |process|
			process.http_port_allocated_form 1400, 4
		end.instance

		expect(instance.ports).to contain_exactly 1400, 1401, 1402, 1403
	end

	# TODO: more tests
end
