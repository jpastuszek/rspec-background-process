require_relative '../spec_helper'

feature 'instance variable replacement', subject: :process_ready_variables do
	# some variables are only available while the instance is about to be started or even after it was forked
	# to be able to use this variables to set up the process run they need to be replaced in arguments etc.

	context 'argument expansion' do
		scenario 'with log file' do
			instance = subject.with do |process|
				process.argument 'log file:<log file>'
			end.instance
			instance.start.wait_ready

			expect(instance.log_file.read).to include "ARGV: [\"log file:#{instance.log_file}\"]"
		end

		scenario 'with pid file' do
			instance = subject.with do |process|
				process.argument 'pid file:<pid file>'
			end.instance
			instance.start.wait_ready

			expect(instance.log_file.read).to include "ARGV: [\"pid file:#{instance.pid_file}\"]"
		end

		scenario 'with working directory' do
			instance = subject.with do |process|
				process.argument 'working directory:<working directory>'
			end.instance
			instance.start.wait_ready

			expect(instance.log_file.read).to include "ARGV: [\"working directory:#{instance.working_directory}\"]"
		end

		scenario 'with instance name' do
			instance = subject.with do |process|
				process.argument 'name:<name>'
			end.instance
			instance.start.wait_ready

			expect(instance.log_file.read).to include "ARGV: [\"name:#{instance.name}\"]"
		end

		scenario 'with project directory' do
			instance = subject.with do |process|
				process.argument 'project directory:<project directory>'
			end.instance
			instance.start.wait_ready

			cwd = Dir.pwd

			expect(instance.log_file.read).to include "ARGV: [\"project directory:#{cwd}\"]"
		end

		context 'server', subject: :http_process_ready_variables do
			scenario 'with port numbers' do
				instance = subject.with do |process|
					process.argument 'port number 1:<allocated port 1>'
					process.argument 'port number 2:<allocated port 2>'
					process.http_port_allocated_form 1700, 2
				end.instance
				instance.start.wait_ready

				expect(instance.log_file.read).to include("ARGV: [\"port number 1:1700\", \"port number 2:1701\"]")
			end
		end
	end
end
