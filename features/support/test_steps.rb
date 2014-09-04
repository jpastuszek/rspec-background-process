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
	(@process_pids ||= {})[name] = _process_pool[name].process.pid
end

Then /^([^ ]+) process pid should be as remembered$/ do |name|
	expect(_process_pool[name].process.pid).to eq((@process_pids ||= {})[name])
end

Then /^([^ ]+) process pid should be different than remembered$/ do |name|
	expect(_process_pool[name].process.pid).to_not eq((@process_pids ||= {})[name])
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
	expect(Pathname.new(file)).to be_file
end

Then /^file (.*) should not exist$/ do |file|
	expect(Pathname.new(file)).to_not be_file
end

Given /^file (.*) content is (.*)/ do |file, content|
	step "file #{file} does not exist"
	Pathname.new(file).open('w') do |file|
		file.write content
	end
end

Then /^([^ ]+) process reports it's current working directory to be the same as current directory/ do |name|
	step "#{name} process log should contain cwd: '#{Dir.pwd}'"
end

Then /^([^ ]+) process reports it's current working directory to be same as log directory/ do |name|
	step "#{name} process log should contain cwd: '#{_process_pool[name].process.log_file.dirname}'"
end

Then /^([^ ]+) process reports it's current working directory to be relative to current working directory by (.*)/ do |name, dir|
	step "#{name} process log should contain cwd: '#{Pathname.new(Dir.pwd) + dir}'"
end

Given /^we remember current working directory$/ do
	@cwd = Dir.pwd
end

And /^current working directory is unchanged$/ do
	expect(Dir.pwd).to eq(@cwd)
end

When /^we remember ([^ ]+) process reported current directory$/ do |name|
	@process_cwd = _process_pool[name].process.log_file.readlines.grep(/cwd: '/).first.match(/cwd: '(.*)'/).captures.first
end

When /^remembered process current directory is different from ([^ ]+) process reported one/ do |name|
	expect(_process_pool[name].process.log_file.readlines.grep(/cwd: '/).first.match(/cwd: '(.*)'/).captures.first).to_not eq(@process_cwd)
end

Then /stopping ([^ ]+) process will not print anything/ do |name|
	expect{
		step "#{name} process is stopped"
	}.to_not output.to_stdout
end

Then /stopping ([^ ]+) process will print (.*)/ do |name, output|
	expect{
		step "#{name} process is stopped"
	}.to output(/#{output}/).to_stdout
end
