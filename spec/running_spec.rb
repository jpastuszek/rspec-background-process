require_relative 'spec_helper'

describe CucumberSpawnProcess::ProcessPool::ProcessDefinition, subject: :shared_process do
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
end
