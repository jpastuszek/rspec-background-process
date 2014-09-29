require_relative 'spec_helper'

describe RSpecBackgroundProcess::BackgroundProcess, subject: :instance do
	describe 'running' do
		it '#command should represent command to be executed' do
			expect(subject.command).to include 'test_process'
		end

		it '#start should spawn the process by calling #spawn' do
			expect(subject).to receive(:spawn).once.and_return([0, Thread.new{}])
			subject.start
		end

		it '#stop should stop the process by sending TERM signal' do
			expect(subject).to receive(:spawn).once.and_return([0, Thread.new{sleep 0.1}])
			subject.start

			expect(Process).to receive(:kill).once.with('TERM', kind_of(Numeric))
			subject.stop
		end

		it '#restart should stop and then start the process' do
			expect(subject).to receive(:spawn).once.and_return([0, Thread.new{sleep 0.1}])
			subject.start

			expect(subject).to receive(:spawn).once.and_return([1, Thread.new{sleep 0.1}])
			expect(Process).to receive(:kill).once.with('TERM', kind_of(Numeric))

			expect {
				subject.restart
			}.to change {
				subject.pid
			}.from(0).to(1)
		end

		describe 'related predicates' do
			it '#pid should be integer when process is running and nil otherwise' do
				expect(subject.pid).to be_nil

				expect(subject).to receive(:spawn).once.and_return([42, Thread.new{sleep 0.1}])
				subject.start

				expect(subject.pid).to be_a(Integer).and eq(42)

				expect(Process).to receive(:kill).once.with('TERM', kind_of(Numeric))
				subject.stop
				expect(subject.pid).to be_nil
			end

			it '#running? should be true when process is running' do
				expect(subject).not_to be_running
				expect(subject).to receive(:spawn).once.and_return([42, Thread.new{sleep 0.1}])
				subject.start
				expect(subject).to be_running
			end

			it '#dead? should be true when process exited but was not stopped by us' do
				expect(subject).not_to be_dead
				expect(subject).to receive(:spawn).once.and_return([42, Thread.new{sleep 0.1}])
				subject.start
				expect(subject).not_to be_dead

				expect(Process).to receive(:kill).once.with('TERM', kind_of(Numeric))
				subject.stop
				expect(subject).not_to be_dead

				expect(subject).to receive(:spawn).once.and_return([42, Thread.new{}])
				subject.start
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
				instance = subject.instance
				expect(instance).to receive(:spawn).once.and_return([42, Thread.new{sleep 0.1}])
				instance.start
				instance.wait_ready
			}.to yield_with_args(RSpecBackgroundProcess::BackgroundProcess)
		end
	end
end
