require_relative '../spec_helper'

feature 'server process with port allocation', subject: :http_process_ready_variables do
	scenario 'allocating port for new process instance form pool' do
		instance = subject.with do |process|
			process.http_port_allocated_form 1400, 4
		end.instance

		expect(instance.ports).to contain_exactly 1400, 1401, 1402, 1403
	end

	scenario 'new ports allocated for new instance' do
		# use up a port
		subject.with do |process|
			process.http_port_allocated_form 1500, 1
		end.instance

		instance = subject.with do |process|
			process.argument 'foo'
			process.http_port_allocated_form 1500, 1
		end.instance

		expect(instance.ports).to contain_exactly 1501
	end

	scenario 'using port number with argument value' do
		instance = subject.with do |process|
			process.argument '--listen', 'localhost:<allocated port 1>'
			process.http_port_allocated_form 1600, 1
		end.instance
		instance.start.wait_ready

		expect(instance.log_file.read).to include('"localhost:1600"').and include('listening on port: 1600')
	end
end
