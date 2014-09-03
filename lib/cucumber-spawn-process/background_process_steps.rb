require_relative 'background_process'
require_relative 'process_pool'

def _process_pool
	@@_process_pool ||= CucumberSpawnProcess::ProcessPool.new
end

def _process(name)
	_process_pool.get(name)
end

Given /^([^ ]+) background process executable is (.*)$/ do |name, path|
	_process_pool.define(name, path, CucumberSpawnProcess::BackgroundProcess)
end

Given /^([^ ]+) background process ruby script is (.*)$/ do |name, path|
	_process_pool.define(name, path, CucumberSpawnProcess::LoadedBackgroundProcess)
end

Given /^([^ ]+) process readiness timeout is (.*) seconds?$/ do |name, seconds|
	_process_pool.options(name, ready_timeout: seconds.to_f)
end

Given /^([^ ]+) process termination timeout is (.*) seconds?$/ do |name, seconds|
	_process_pool.options(name, term_timeout: seconds.to_f)
end

Given /^([^ ]+) process kill timeout is (.*) seconds?$/ do |name, seconds|
	_process_pool.options(name, kill_timeout: seconds.to_f)
end

Given /^([^ ]+) process is ready when log file contains (.*)/ do |name, log_line|
	_process_pool.options(name,
		ready_test: ->(process) do
			process.log_file.open do |log|
				loop do
					line = log.gets and line.include?(log_line) and break
					sleep 0.1
				end
				true
			end
		end
	)
end

Given /^([^ ]+) process is refreshed with command (.*)/ do |name, command|
	_process_pool.options(name,
		refresh_action: ->(process) do
			system command
		end
	)
end

Given /^([^ ]+) process working directory is changed to (.*)/ do |name, dir|
	_process_pool.working_directory(name, dir)
end

Given /^([^ ]+) process working directory is the same as current working directory/ do |name|
	_process_pool.working_directory(name, Dir.pwd)
end

Given /^([^ ]+) process argument (.*)/ do |name, argument|
	_process_pool.arguments(name) << argument
end

Given /^([^ ]+) process file argument (.*)/ do |name, argument|
	_process_pool.arguments(name) << Pathname.new(argument)
end

Given /^([^ ]+) process option (.*) with value (.*)/ do |name, option, value|
	_process_pool.arguments(name) << option
	_process_pool.arguments(name) << value
end

Given /^([^ ]+) process option (.*) with file value (.*)/ do |name, option, value|
	_process_pool.arguments(name) << option
	_process_pool.arguments(name) << Pathname.new(value)
end

Given /^([^ ]+) process is running$/ do |name|
	_process(name).start
end

Given /^fresh ([^ ]+) process is running$/ do |name|
	_process(name).running? ? _process(name).refresh : _process(name).start
end

When /^([^ ]+) process is stopped$/ do |name|
	_process(name).stop
end

Given /^([^ ]+) process is ready$/ do |name|
	_process(name).verify
end

Given /^([^ ]+) process is running and ready$/ do |name|
	step "#{name} process is running"
	step "#{name} process is ready"
end

Given /^fresh ([^ ]+) process is running and ready$/ do |name|
	step "fresh #{name} process is running"
	step "#{name} process is ready"
end

Given /^([^ ]+) process is refreshed$/ do |name|
	_process(name).refresh
end

Given /^([^ ]+) process is refreshed and ready$/ do |name|
	step "#{name} process is refreshed"
	step "#{name} process is ready"
end

Given /^I wait ([^ ]+) seconds for process to settle$/ do |seconds|
	sleep seconds.to_f
end

Then /^([^ ]+) process log should contain (.*)/ do |name, log_line|
	expect(_process(name).log_file.readlines).to include(
		a_string_including(log_line)
	)
end

Then /^([^ ]+) process log should not contain (.*)/ do |name, log_line|
	expect(_process(name).log_file.readlines).to_not include(
		a_string_including(log_line)
	)
end

Then /^([^ ]+) process log should match (.*)/ do |name, regexp|
	expect(_process(name).log_file.readlines).to include(
		a_string_matching(Regexp.new regexp)
	)
end

Then /^([^ ]+) process log should not match (.*)/ do |name, regexp|
	expect(_process(name).log_file.readlines).to_not include(
		a_string_matching(Regexp.new regexp)
	)
end

Then /^([^ ]+) process should be running/ do |name|
	expect(_process(name)).to be_running
end

Then /^([^ ]+) process should not be running/ do |name|
	expect(_process(name)).to_not be_running
end

Then /^([^ ]+) process should be ready/ do |name|
	expect(_process(name)).to be_ready
end

Then /^([^ ]+) process should not be ready/ do |name|
	expect(_process(name)).to_not be_ready
end

Then /^([^ ]+) process should be dead/ do |name|
	expect(_process(name)).to be_dead
end

Then /^([^ ]+) process should not be dead/ do |name|
	expect(_process(name)).to_not be_dead
end

Then /^([^ ]+) process should be failed/ do |name|
	expect(_process(name)).to be_failed
end

Then /^([^ ]+) process should not be failed/ do |name|
	expect(_process(name)).to_not be_failed
end

Then /^([^ ]+) process should be jammed/ do |name|
	expect(_process(name)).to be_jammed
end

Then /^([^ ]+) process should not be jammed/ do |name|
	expect(_process(name)).to_not be_jammed
end

Then /^([^ ]+) exit code should be (\d+)$/ do |name, exit_code|
	expect(_process(name).exit_code).to eq(exit_code.to_i)
end

Then /^([^ ]+) process readiness timeout should be (.*)/ do |name, seconds|
	expect(_process(name).ready_timeout).to eq(seconds.to_f)
end

Then /^([^ ]+) process termination timeout should be (.*)/ do |name, seconds|
	expect(_process(name).term_timeout).to eq(seconds.to_f)
end

Then /^([^ ]+) process kill timeout should be (.*)/ do |name, seconds|
	expect(_process(name).kill_timeout).to eq(seconds.to_f)
end
