require_relative 'spec_helper'

describe CucumberSpawnProcess::BackgroundProcess, subject: :instance do
	describe 'running' do
		it '#start should spawn the process' do
			subject.start

			pid = subject.pid

			Process.kill('TERM', pid)
			sleep 0.2

			expect {
				Process.kill('TERM', pid)
			}.to raise_error Errno::ESRCH
		end

		it '#stop should stop the process' do
			subject.start
			pid = subject.pid

			subject.stop
			expect {
				Process.kill('TERM', pid)
			}.to raise_error Errno::ESRCH
		end

		it '#restart should stop and then start the process' do
			subject.start
			pid = subject.pid

			subject.restart
			expect(subject.pid).not_to eq(pid)
		end

		describe 'related predicates' do
			it '#pid should be integer when process is running and nil otherwise' do
				expect(subject.pid).to be_nil
				subject.start
				expect(subject.pid).to be_a(Integer).and be > 0
				subject.stop
				expect(subject.pid).to be_nil
			end

			it '#running? should be true when process is running' do
				expect(subject).not_to be_running
				subject.start
				expect(subject).to be_running
			end

			it '#dead? should be true when process exited but was not stopped by us' do
				expect(subject).not_to be_dead
				subject.start
				expect(subject).not_to be_dead

				subject.stop
				expect(subject).not_to be_dead

				subject.start
				Process.kill('TERM', subject.pid)
				sleep 0.2
				expect(subject).to be_dead
			end
		end
	end
end
