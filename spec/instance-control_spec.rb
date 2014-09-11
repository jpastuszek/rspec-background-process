require_relative 'spec_helper'

describe 'instance control', subject: :shared_instance do
	it '#start should spawn the process' do
		expect(subject.start).to be_running
	end

	it '#stop should stop the process' do
		subject.start
		expect(subject.stop).not_to be_running
	end
end
