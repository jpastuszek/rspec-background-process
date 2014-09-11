require_relative 'spec_helper'

describe SpawnProcessHelpers do
	describe '#process_pool' do
		it 'should provide singleton pool object ' do
			p1 = process_pool
			p2 = process_pool

			expect(p1).to eq(p2)
		end
	end

	describe '#background_process' do
		it 'should allow specifying executable to run' do
			process = background_process('features/support/test_process')
			expect(process.instance.command).to include 'features/support/test_process'
		end

		describe 'load option' do
			it 'when set to true will change instance type to LoadedBackgroundProcess' do
				process = background_process('features/support/test_process', load: true)
				expect(process.instance).to be_a CucumberSpawnProcess::LoadedBackgroundProcess
			end
		end

		it 'should return process definition' do
			process = background_process('features/support/test_process')
			expect(process).to be_a CucumberSpawnProcess::ProcessPool::ProcessDefinition
		end
	end

	describe CucumberSpawnProcess::ProcessPool::ProcessDefinition do
		subject do
			background_process('features/support/test_process')
		end

		def instance
			subject.instance
		end

		describe '#with' do
			it 'should execute passed block it in context of cloned process definition' do
				ctx = nil

				subject.with do
					ctx = self
				end

				expect(ctx).to be_a CucumberSpawnProcess::ProcessPool::ProcessDefinition
				expect(ctx).not_to eq(subject)
			end
		end

		describe '#argument' do
			it 'should pass given argument to command' do
				subject.argument 'foo bar'
				subject.argument 'baz'

				expect(instance.command).to include 'foo\\ bar'
				expect(instance.command).to include 'baz'
			end

			it 'should pass given option argument to command' do
				subject.argument '--foo', 'bar'
				subject.argument '--baz', 'hello world'

				expect(instance.command).to include '--foo bar'
				expect(instance.command).to include '--baz hello\\ world'
			end
		end

		describe '#with_logging' do
			it 'should make the instance to print out state changes' do
				subject.logging_enabled

				expect {
					instance.start
				}.to output(
					a_string_including 'process is now running'
				).to_stdout
			end
		end
	end

	example 'defining process variation with #with' do
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
