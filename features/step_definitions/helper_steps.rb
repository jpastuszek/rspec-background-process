# used for testing internally

Given /^(#{PROCESS}) exits prematurely/ do |process|
	expect {
		step "#{process.name} process is running"
	}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessExitedError
end

Given /(#{PROCESS}) readiness fails with falsy value/ do |process|
	process.options(
		ready_test: ->(process) do
			false
		end
	)
end

Given /(#{PROCESS}) readiness fails with exception/ do |process|
	process.options(
		ready_test: ->(process) do
			fail 'check fail test error'
		end
	)
end

Then /defining ([^ ]+) background process again should fail/ do |name|
	expect {
		step "#{name} background process executable is features/support/test_process"
	}.to raise_error RuntimeError, "redefining background process '#{name}' is not allowed"
end

Then /following steps should fail with ([^ ]+): (.*)/ do |error, msg, steps|
	steps.raw.each do |step|
		expect {
			step step.first
		}.to raise_error eval(error), msg
	end
end

Then /^(#{PROCESS}) should fail to become ready in time$/ do |process|
	expect {
		step "#{process.name} process is ready"
	}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessReadyTimeOutError
end

Then /^(#{PROCESS}) should fail to become ready with failed error/ do |process|
	expect {
		step "#{process.name} process is ready"
	}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessReadyFailedError
end

Then /^(#{PROCESS}) should fail to become ready with exception/ do |process|
	expect {
		step "#{process.name} process is ready"
	}.to raise_error RuntimeError, 'check fail test error'
end

Then /^(#{PROCESS}) should fail to stop$/ do |process|
	expect {
		step "#{process.name} process is stopped"
	}.to raise_error CucumberSpawnProcess::BackgroundProcess::ProcessRunAwayError
end

Given /we remember (#{PROCESS}) pid/ do |process|
	$process_pid = process.instance.pid
end

Then /^(#{PROCESS}) pid should be as remembered$/ do |process|
	expect($process_pid).to_not be_nil
	expect(process.instance.pid).to eq($process_pid)
end

Then /^(#{PROCESS}) pid should be different than remembered$/ do |process|
	expect($process_pid).to_not be_nil
	expect(process.instance.pid).to_not eq($process_pid)
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

Then /^file (.*) should contain (.*)/ do |file, content|
	expect(Pathname.new(file).read.strip).to eq content
end

Given /^file (.*) content is (.*)/ do |file, content|
	step "file #{file} does not exist"
	Pathname.new(file).open('w') do |file|
		file.write content
	end
end

Then /^(#{PROCESS}) reports it's current working directory to be the same as current directory/ do |process|
	step "#{process.name} process log should contain cwd: '#{Dir.pwd}'"
end

Then /^(#{PROCESS}) reports it's current working directory to be same as log directory/ do |process|
	step "#{process.name} process log should contain cwd: '#{process.instance.log_file.dirname}'"
end

Then /^(#{PROCESS}) reports it's current working directory to be relative to current working directory by (.*)/ do |process, dir|
	step "#{process.name} process log should contain cwd: '#{Pathname.new(Dir.pwd) + dir}'"
end

Given /^we remember current working directory$/ do
	@cwd = Dir.pwd
end

And /^current working directory is unchanged$/ do
	expect(Dir.pwd).to eq(@cwd)
end

When /^we remember (#{PROCESS}) reported current directory$/ do |process|
	@process_cwd = process.instance.log_file.readlines.grep(/cwd: '/).first.match(/cwd: '(.*)'/).captures.first
end

When /^remembered process current directory is different from (#{PROCESS}) reported one/ do |process|
	expect(process.instance.log_file.readlines.grep(/cwd: '/).first.match(/cwd: '(.*)'/).captures.first).to_not eq(@process_cwd)
end

Then /stopping (#{PROCESS}) will not print anything/ do |process|
	expect{
		step "#{process.name} process is stopped"
	}.to_not output.to_stdout
end

Given /this scenario fail/ do
	fail 'forced scenario failure'
end

Then /stopping (#{PROCESS}) will print (.*)/ do |process, output|
	expect{
		step "#{process.name} process is stopped" rescue true
	}.to output(/#{output}/).to_stdout
end

Then /stopping (#{PROCESS}) will report to STDERR/ do |process|
	expect{
		step "#{process.name} process is stopped" rescue true
	}.to output.to_stderr
end

Then /(#{PROCESS}) should have ports? (.*) allocated/ do |process, ports|
	expect(process.instance.ports).to contain_exactly *ports.split(/, +/).map(&:to_i)
end
