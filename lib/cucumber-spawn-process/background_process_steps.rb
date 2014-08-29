require_relative 'background_process'
require_relative 'process_pool'

def _process_pool
	@@process_pool ||= CucumberSpawnProcess::ProcessPool.new
end

Given /^([^ ]+) background process executable is (.*)$/ do |name, path|
	_process_pool.define(name, path, CucumberSpawnProcess::BackgroundProcess)
	(@process_arguments ||= {})[name] = []
end

Given /^([^ ]+) process is running$/ do |name|
	_process_pool.get(name, @process_arguments[name]).start
end

Given /^([^ ]+) process readiness timeout is (.*) seconds?$/ do |name, seconds|
	_process_pool.get(name, @process_arguments[name]).ready_timeout = seconds.to_f
end

Given /^([^ ]+) process is ready when log file contains (.*)/ do |name, log_line|
	_process_pool.get(name, @process_arguments[name]).ready_when do |process|
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
	_process_pool.get(name, @process_arguments[name]).log_file.read.should include log_line
end

# used for testing internaly but my come handy

Then /^([^ ]+) process should fail to start in time$/ do |name|
	expect {
		step "#{name} process is running"
	}.to raise_error Timeout::Error
end

Then /^kill myself/ do
	sleep 1
	Process.kill(9, Process.pid)
end
