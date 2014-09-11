require_relative 'spec_helper'

describe CucumberSpawnProcess::ProcessPool::ProcessDefinition, subject: :fresh_process  do
	specify 'logging should be disabled by default' do
		expect {
			instance.start
		}.not_to output.to_stdout
	end

	describe '#logging_enable' do
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
