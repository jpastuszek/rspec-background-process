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

Given /^I wait ([^ ]+) seconds for process to settle$/ do |seconds|
	sleep seconds.to_f
end

Then /^([^ ]+) process log should contain (.*)/ do |name, log_line|
	_process_pool.get(name, @process_arguments[name]).log_file.read.should include log_line
end

Then /^kill myself/ do
	sleep 1
	Process.kill(9, Process.pid)
end
