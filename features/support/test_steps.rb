# used for testing internally

Given /^([^ ]+) process exits prematurely/ do |name|
	expect {
		step "#{name} process is running"
	}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessExitedError
end

Then /^([^ ]+) process should fail to become ready in time$/ do |name|
	expect {
		step "#{name} process is ready"
	}.to raise_error Timeout::Error
end

Then /^([^ ]+) process should fail to stop$/ do |name|
	expect {
		step "#{name} process is stopped"
	}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessRunAwayError
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

require 'shellwords'
require 'pathname'

Given /^file (.*) does not exist$/ do |file|
	Pathname.new(file).file? and system Shellwords.join(['rm', file])
end

Then /^file (.*) should exist$/ do |file|
	Pathname.new(file).should be_file
end

Then /^file (.*) should not exist$/ do |file|
	Pathname.new(file).should_not be_file
end
