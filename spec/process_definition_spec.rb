require_relative 'spec_helper'

describe CucumberSpawnProcess::ProcessPool::ProcessDefinition, subject: :process do
	describe '#with' do
		it 'should execute passed block it in context of cloned process definition' do
			expect { |b|
				subject.with(&b)
			}.to yield_with_args(
				an_instance_of(CucumberSpawnProcess::ProcessPool::ProcessDefinition)
				.and different_than subject
			)
		end

		example 'defining process variation' do
			hello_process = background_process('features/support/test_process').with do |process|
				process.argument 'hello'
				process.logging_enabled
			end

			hello_foo_bar_process = hello_process.with do |process|
				process.argument 'foo-bar'
			end

			expect {
				hello_process.start
			}.to output(
				a_string_matching 'starting.*features/support/test_process hello`'
			).to_stdout

			expect {
				hello_foo_bar_process.start
			}.to output(
				a_string_matching 'starting.*features/support/test_process hello foo-bar'
			).to_stdout
		end
	end

	describe '#instance' do
		it 'should create new process instance' do
			expect(CucumberSpawnProcess::BackgroundProcess).to receive(:new)
			.and_call_original

			subject.instance
		end

		it 'should not crate new process when called more than once' do
			expect(CucumberSpawnProcess::BackgroundProcess).to receive(:new)
			.once
			.and_call_original

			subject.instance
			subject.instance
		end
	end

	describe '#argument' do
		it 'should pass given argument to process' do
			expect(CucumberSpawnProcess::BackgroundProcess).to receive(:new)
			.with(anything, anything, a_collection_containing_exactly('foo bar', 'baz'), anything, anything)
			.and_call_original

			subject.argument 'foo bar'
			subject.argument 'baz'

			subject.instance
		end

		it 'should pass given option argument to process' do
			expect(CucumberSpawnProcess::BackgroundProcess).to receive(:new)
			.with(anything, anything, a_collection_containing_exactly('--foo', 'bar', '--baz', 'hello world'), anything, anything)
			.and_call_original

			subject.argument '--foo', 'bar'
			subject.argument '--baz', 'hello world'

			subject.instance
		end
	end

	describe '#extend' do
		it 'should extend instance with given extension' do
			TestExtension = Module.new
			extension = class_spy('TestExtension')

			process = subject.with do |process|
				process.extend extension
			end

			# used for key generation
			expect(extension).to receive(:name).and_return('test')

			# actually used to extend background process
			expect(extension).to receive(:extended) do |instance|
				expect(instance).to be_an_instance_of(CucumberSpawnProcess::LoadedBackgroundProcess)
			end.once

			process.instance
		end
	end

	describe '#read_timeout' do
		it 'should pass given argument to process' do
			expect(CucumberSpawnProcess::BackgroundProcess).to receive(:new)
			.with(anything, anything, anything, anything, a_hash_including(ready_timeout: 42))
			.and_call_original

			subject.ready_timeout 42

			subject.instance
		end
	end

	describe '#term_timeout' do
		it 'should pass given argument to process' do
			expect(CucumberSpawnProcess::BackgroundProcess).to receive(:new)
			.with(anything, anything, anything, anything, a_hash_including(term_timeout: 42))
			.and_call_original

			subject.term_timeout 42

			subject.instance
		end
	end

	describe '#kill_timeout' do
		it 'should pass given argument to process' do
			expect(CucumberSpawnProcess::BackgroundProcess).to receive(:new)
			.with(anything, anything, anything, anything, a_hash_including(kill_timeout: 42))
			.and_call_original

			subject.kill_timeout 42

			subject.instance
		end
	end

	describe '#ready_test' do
		it 'should register a block to be called when process is verified' do
			expect { |b|
				subject.ready_test do |*args|
					b.to_proc.call(*args)
					# need to return true
					true
				end

				#TODO: only test if the block was passed to the instance
				subject.instance.start.wait_ready
			}.to yield_control
		end
	end

	describe 'logging' do
		specify 'logging should be disabled by default' do
			process_pool.logging_enabled? and skip 'logging enabled by default'
			expect {
				subject.instance.start
			}.not_to output.to_stdout
		end

		describe '#logging_enable' do
			it 'should make the instance to print out state changes' do
				subject.logging_enabled

				expect {
					subject.instance.start
				}.to output(
					a_string_including 'process is now running'
				).to_stdout
			end
		end

		describe '#logging_enabled?' do
			it 'should be true when instance logging is enabled' do
				process_pool.logging_enabled? and skip 'logging enabled by default'

				expect(subject).not_to be_logging_enabled
				subject.logging_enabled
				expect(subject).to be_logging_enabled
			end
		end
	end
end
