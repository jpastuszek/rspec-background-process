require_relative '../spec_helper'

feature 'server process with port allocation', subject: :http_process do
	scenario 'allocating port for new process instance form pool' do
		instance = subject.with do |process|
			process.http_port_allocated_form 1200
		end.instance

		expect(instance.ports).to contain_exactly 1200
	end

	# TODO: more tests
end
