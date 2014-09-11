require_relative 'spec_helper'

describe CucumberSpawnProcess::ProcessPool::ProcessDefinition, subject: :shared_process do
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
