require_relative 'spec_helper'

describe CucumberSpawnProcess::ProcessPool::ProcessDefinition, subject: :process do
	describe '#with' do
		it 'should execute passed block it in context of cloned process definition' do
			ctx = nil

			subject.with do
				ctx = self
			end

			expect(ctx).to be_a CucumberSpawnProcess::ProcessPool::ProcessDefinition
			expect(ctx).not_to eq(subject)
		end

		example 'defining process variation' do
			hello_process = background_process('features/support/test_process').with do
				argument 'hello'
				logging_enabled
			end

			hello_foo_bar_process = hello_process.with do
				argument 'foo-bar'
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

	describe '#argument' do
		it 'should pass given argument to command' do
			subject.argument 'foo bar'
			subject.argument 'baz'

			expect(subject.instance.command).to include 'foo\\ bar'
			expect(subject.instance.command).to include 'baz'
		end

		it 'should pass given option argument to command' do
			subject.argument '--foo', 'bar'
			subject.argument '--baz', 'hello world'

			expect(subject.instance.command).to include '--foo bar'
			expect(subject.instance.command).to include '--baz hello\\ world'
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
