require_relative 'spec_helper'

describe 'instance control' do
	subject do
		background_process('features/support/test_process').instance
	end

	it '#start should spawn the executable' do
		expect(subject.start).to be_running
	end
end
