require_relative 'spec_helper'

describe CucumberSpawnProcess::BackgroundProcess, subject: :instance do
	describe 'running' do
		it '#command should represent command to be executed' do
			expect(subject.command).to include 'test_process'
		end

		it '#start should spawn the process with Kernel.fork' do
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

			expect {
				subject.restart
			}.to change {
				subject.pid
			}
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

	describe 'readiness', subject: :process do
		it 'instance #wait_ready should call readiness block with self as argument' do
			expect { |b|
				subject.ready_test do |*args|
					b.to_proc.call(*args)
					# need to return true
					true
				end
				subject.instance.start.wait_ready
			}.to yield_with_args(CucumberSpawnProcess::BackgroundProcess)
		end
	end
end
