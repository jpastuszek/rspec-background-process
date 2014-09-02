require_relative 'background_process'
require_relative 'process_pool'

def _process_pool
	@@_process_pool ||= CucumberSpawnProcess::ProcessPool.new
end

def _process(name)
	_process_pool.get(name, @process_arguments[name])
end

Given /^([^ ]+) background process executable is (.*)$/ do |name, path|
	_process_pool.define(name, path, CucumberSpawnProcess::BackgroundProcess)
	(@process_arguments ||= {})[name] = []
end

Given /^([^ ]+) background process ruby script is (.*)$/ do |name, path|
	_process_pool.define(name, path, CucumberSpawnProcess::LoadedBackgroundProcess)
	(@process_arguments ||= {})[name] = []
end

Given /^([^ ]+) process is running$/ do |name|
	_process(name).start.verify
end

Given /^([^ ]+) process is refreshed$/ do |name|
	_process(name).refresh.verify
end

Given /^([^ ]+) process readiness timeout is (.*) seconds?$/ do |name, seconds|
	_process(name).ready_timeout = seconds.to_f
end

Given /^([^ ]+) process is ready when log file contains (.*)/ do |name, log_line|
	_process(name).ready_when do |process|
		process.log_file.open do |log|
			loop do
				line = log.gets and line.include?(log_line) and break
				sleep 0.1
			end
			true
		end
	end
end

Given /^I wait ([^ ]+) seconds for process to settle$/ do |seconds|
	sleep seconds.to_f
end

Then /^([^ ]+) process log should contain (.*)/ do |name, log_line|
	_process(name).log_file.read.should include log_line
end

Then /^([^ ]+) process log should not contain (.*)/ do |name, log_line|
	_process(name).log_file.read.should_not include log_line
end

Then /^([^ ]+) process should be running/ do |name|
	_process(name).should be_running
end

Then /^([^ ]+) process should not be running/ do |name|
	_process(name).should_not be_running
end

Then /^([^ ]+) process should be ready/ do |name|
	_process(name).should be_ready
end

Then /^([^ ]+) process should not be ready/ do |name|
	_process(name).should_not be_ready
end

Then /^([^ ]+) exit code should be (\d+)$/ do |name, exit_code|
	_process(name).exit_code.should_not be_nil
	_process(name).exit_code.should == exit_code.to_i
end

# used for testing internally but my come handy

Given /^([^ ]+) process exits prematurely/ do |name|
	expect {
		step "#{name} process is running"
	}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessExitedError
end

Then /^([^ ]+) process should fail to start in time$/ do |name|
	expect {
		step "#{name} process is running"
	}.to raise_error Timeout::Error
end

Given /we remember ([^ ]+) process pid/ do |name|
	(@process_pids ||= {})[name] = _process(name).pid
end

Then /^([^ ]+) process pid should be as remembered$/ do |name|
	_process(name).pid.should == (@process_pids ||= {})[name]
end

Then /^([^ ]+) process pid should be different than remembered$/ do |name|
	_process(name).pid.should_not == (@process_pids ||= {})[name]
end

Then /^kill myself/ do
	sleep 1
	Process.kill(9, Process.pid)
end
