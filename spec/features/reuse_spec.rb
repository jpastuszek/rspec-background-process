require_relative '../spec_helper'

feature 'processes with same definition reuse single instance', subject: :process do
	context 'arguments' do
		scenario 'defining two instances with same arguments' do
			instance1 = subject.with{|p| p.argument 'foo'}.instance
			instance2 = subject.with{|p| p.argument 'foo'}.instance

			expect(instance1).to eq(instance2)
		end

		scenario 'defining two instances with different arguments' do
			instance1 = subject.with{|p| p.argument 'foo'}.instance
			instance2 = subject.with{|p| p.argument 'bar'}.instance

			expect(instance1).not_to eq(instance2)
		end
	end

	context 'working directory' do
		scenario 'defining two instances with same working directory' do
			instance1 = subject.with{|p| p.working_directory 'foo'}.instance
			instance2 = subject.with{|p| p.working_directory 'foo'}.instance

			expect(instance1).to eq(instance2)
		end

		scenario 'defining two instances with different working directory' do
			instance1 = subject.with{|p| p.working_directory 'foo'}.instance
			instance2 = subject.with{|p| p.working_directory 'bar'}.instance

			expect(instance1).not_to eq(instance2)
		end
	end

	context 'extensions' do
		scenario 'defining two instances with same extensions but different options' do
			instance1 = subject.with{|p| p.extend RSpecBackgroundProcess::BackgroundProcess::Server, port_count: 3, base_port: 1200}.instance
			instance2 = subject.with{|p| p.extend RSpecBackgroundProcess::BackgroundProcess::Server, port_count: 1, base_port: 1200}.instance

			expect(instance1).to eq(instance2)
		end

		scenario 'defining two instances with different extensions' do
			instance1 = subject.instance
			instance2 = subject.with{|p| p.extend RSpecBackgroundProcess::BackgroundProcess::Server, port_count: 1, base_port: 1200}.instance

			expect(instance1).not_to eq(instance2)
		end
	end

	context 'options not affecting instance key (reused)' do
		scenario 'logging settings differ' do
			instance1 = subject.instance
			instance2 = subject.with{|p| p.logging_enabled}.instance

			expect(instance1).to eq(instance2)
		end

		scenario 'ready test differ' do
			instance1 = subject.with{|p| p.ready_test{|i| false}}.instance
			instance2 = subject.with{|p| p.ready_test{|i| true}}.instance

			expect(instance1).to eq(instance2)
		end

		scenario 'refresh action differ' do
			instance1 = subject.with{|p| p.refresh_action{|i| false}}.instance
			instance2 = subject.with{|p| p.refresh_action{|i| true}}.instance

			expect(instance1).to eq(instance2)
		end

		scenario 'timeouts differ' do
			instance1 = subject.with{|p| p.ready_timeout(1); p.kill_timeout(1); p.term_timeout(1)}.instance
			instance2 = subject.with{|p| p.ready_timeout(2); p.kill_timeout(2); p.term_timeout(2)}.instance

			expect(instance1).to eq(instance2)
		end
	end
end
