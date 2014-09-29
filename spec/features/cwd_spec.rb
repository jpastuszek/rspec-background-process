require_relative '../spec_helper'

def process_cwd_from_log(log)
	log.readlines.grep(/^cwd:/).first.split(': ', 2).last.match(/'(.*)'/).captures.first.strip || fail('cannot extract cwd from log')
end

feature 'auto managing current working directory', subject: :process_ready_variables do
	scenario 'processes by default run in own different directory' do
		instance1 = subject.start.wait_ready
		instance2 = subject.with{|p| p.argument 'blah'}.start.wait_ready

		# reported cwd
		expect(instance1.working_directory.to_s).not_to eq(instance2.working_directory.to_s)

		# actual cwd
		expect(process_cwd_from_log(instance1.log_file)).to eq(instance1.working_directory.realpath.to_s)
		expect(process_cwd_from_log(instance2.log_file)).to eq(instance2.working_directory.realpath.to_s)
	end
end

feature 'process current working directory does not affect test current directory', subject: :process_ready_variables do
	scenario 'master process current working directory unchanged over instance start' do
		expect {
			subject.start.wait_ready
		}.not_to change {
			Dir.pwd
		}

		# reported cwd
		expect(subject.instance.working_directory.to_s).not_to eq(Dir.pwd)

		# actual cwd
		expect(process_cwd_from_log(subject.instance.log_file)).to eq(subject.instance.working_directory.realpath.to_s)
	end
end

feature 'current working directory can be configured to custom directory', subject: :process_ready_variables do
	let :test_dir do
		Pathname.new(Dir.pwd) + 'tmp'
	end

	scenario 'setting current working directory to test directory' do
		instance = subject.with{|p| p.working_directory test_dir}.start.wait_ready

		# reported cwd
		expect(instance.working_directory.to_s).to eq(test_dir.to_s)

		# actual cwd
		expect(process_cwd_from_log(instance.log_file)).to eq(instance.working_directory.realpath.to_s)
	end
end
