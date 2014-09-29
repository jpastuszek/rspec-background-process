require_relative '../spec_helper'

feature 'process pool can keep limited number of processes running between test evicting processes using LRU', subject: :process do
	scenario 'extra LRU processes (over 4 by default) are stopped between tests' do
		instances = []
		instances << subject.with{|p| p.argument '1'}.start
		instances << subject.with{|p| p.argument '2'}.start
		instances << subject.with{|p| p.argument '3'}.start
		instances << subject.with{|p| p.argument '4'}.start
		instances << subject.with{|p| p.argument '5'}.start

		# keeps all running
		expect(instances).to all be_running

		# let LRU do the job (executed after each scenario/example)
		process_pool.cleanup

		# first instance should not be running (LRU)
		expect(instances.shift).not_to be_running
		# remaining 4 should be kept running
		expect(instances).to all be_running
	end
end
