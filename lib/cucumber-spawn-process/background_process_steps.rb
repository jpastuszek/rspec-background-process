require_relative 'background_process'
require_relative 'background_process_server'
require_relative 'process_pool'
require 'open-uri'
require 'file-tail'

def _process_pool(options = {})
	@@_process_pool ||= CucumberSpawnProcess::ProcessPool.new(options)
end

# env.rb:
#require 'cucumber-spawn-process'
#
# Uncomment to change defaults
#_process_pool(logging: false, max_running: 4)
#
# Uncomment to see LRU stats
#at_exit do
#	_process_pool.report_stats
#end

After do |scenario|
	_process_pool.reset_active
	if scenario.failed?
		if failed_process = _process_pool.failed_process
			STDERR.puts "Last failed process state log: "
			failed_process.state_log.each do |log_line|
				STDERR.puts "\t#{log_line}"
			end
			STDERR.puts "Working directory: #{failed_process.working_directory}"
			STDERR.puts "Log file: #{failed_process.log_file}"
			STDERR.puts "State: #{failed_process.state}"
			STDERR.puts "Exit code: #{failed_process.exit_code}"
		end
	end
end

PROCESS = Transform /^([^ ]+) process$/ do |name|
	_process_pool[name]
end

Given /^([^ ]+) background process executable is (.*)$/ do |name, path|
	_process_pool.define(name, path, CucumberSpawnProcess::BackgroundProcess)
end

Given /^([^ ]+) background process ruby script is (.*)$/ do |name, path|
	_process_pool.define(name, path, CucumberSpawnProcess::LoadedBackgroundProcess)
end

Given /^(#{PROCESS}) is a server with (\d+) ports? allocated from (\d+) up/ do |process, port_count, base_port|
	process.extend(CucumberSpawnProcess::BackgroundProcess::Server, port_count: port_count.to_i, base_port: base_port.to_i)
end

Given /^(#{PROCESS}) readiness timeout is (.*) seconds?$/ do |process, seconds|
	process.options(ready_timeout: seconds.to_f)
end

Given /^(#{PROCESS}) termination timeout is (.*) seconds?$/ do |process, seconds|
	process.options(term_timeout: seconds.to_f)
end

Given /^(#{PROCESS}) kill timeout is (.*) seconds?$/ do |process, seconds|
	process.options(kill_timeout: seconds.to_f)
end

Given /^(#{PROCESS}) is ready when log file contains (.*)/ do |process, log_line|
	process.options(
		ready_test: ->(process) do
			File::Tail::Logfile.tail(process.log_file, forward: 0, interval: 0.01, max_interval: 1, suspicious_interval: 4) do |line|
				line.include?(log_line) and break true
			end
		end
	)
end

Given /^(#{PROCESS}) is ready when URI (.*) response status is (.*)/ do |process, uri, status|
	process.options(
		ready_test: ->(process) do
			backoff = 0.06
			grow = 2
			max = 1

			begin
				open(uri).status.last.strip == status and break true
			rescue Errno::ECONNREFUSED
				sleep backoff
				backoff *= grow
				backoff = max if backoff > max
				retry
			end
		end
	)
end

Given /^(#{PROCESS}) is refreshed with command (.*)/ do |process, command|
	process.options(
		refresh_action: ->(process) do
			system command
		end
	)
end

Given /^(#{PROCESS}) logging is enabled/ do |process|
	process.options(logging: true)
end

Given /^(#{PROCESS}) working directory is changed to (.*)/ do |process, dir|
	process.working_directory(dir)
end

Given /^(#{PROCESS}) working directory is the same as current working directory/ do |process|
	process.working_directory(Dir.pwd)
end

Given /^(#{PROCESS}) argument (.*)/ do |process, argument|
	process.arguments << argument
end

Given /^(#{PROCESS}) file argument (.*)/ do |process, argument|
	process.arguments << Pathname.new(argument)
end

Given /^(#{PROCESS}) option (.*) with value (.*)/ do |process, option, value|
	process.arguments << option
	process.arguments << value
end

Given /^(#{PROCESS}) option (.*) with file value (.*)/ do |process, option, value|
	process.arguments << option
	process.arguments << Pathname.new(value)
end

Given /^(#{PROCESS}) is running$/ do |process|
	process.process.start
end

Given /^fresh (#{PROCESS}) is running$/ do |process|
	process.process.running? ? process.process.refresh : process.process.start
end

When /^(#{PROCESS}) is stopped$/ do |process|
	process.process.stop
end

Given /^(#{PROCESS}) is ready$/ do |process|
	process.process.verify
end

Given /^(#{PROCESS}) is running and ready$/ do |process|
	step "#{process.name} process is running"
	step "#{process.name} process is ready"
end

Given /^fresh (#{PROCESS}) is running and ready$/ do |process|
	step "fresh #{process.name} process is running"
	step "#{process.name} process is ready"
end

Given /^(#{PROCESS}) is refreshed$/ do |process|
	process.process.refresh
end

Given /^(#{PROCESS}) is refreshed and ready$/ do |process|
	step "#{process.name} process is refreshed"
	step "#{process.name} process is ready"
end

Given /^I wait ([^ ]+) seconds for process to settle$/ do |seconds|
	sleep seconds.to_f
end

Then /^(#{PROCESS}) log should contain (.*)/ do |process, log_line|
	expect(process.process.log_file.readlines).to include(
		a_string_including(log_line)
	)
end

Then /^(#{PROCESS}) log should not contain (.*)/ do |process, log_line|
	expect(process.process.log_file.readlines).to_not include(
		a_string_including(log_line)
	)
end

Then /^(#{PROCESS}) log should match (.*)/ do |process, regexp|
	expect(process.process.log_file.readlines).to include(
		a_string_matching(Regexp.new regexp)
	)
end

Then /^(#{PROCESS}) log should not match (.*)/ do |process, regexp|
	expect(process.process.log_file.readlines).to_not include(
		a_string_matching(Regexp.new regexp)
	)
end

Then /^(#{PROCESS}) should be running/ do |process|
	expect(process.process).to be_running
end

Then /^(#{PROCESS}) should not be running/ do |process|
	expect(process.process).to_not be_running
end

Then /^(#{PROCESS}) should be ready/ do |process|
	expect(process.process).to be_ready
end

Then /^(#{PROCESS}) should not be ready/ do |process|
	expect(process.process).to_not be_ready
end

Then /^(#{PROCESS}) should be dead/ do |process|
	expect(process.process).to be_dead
end

Then /^(#{PROCESS}) should not be dead/ do |process|
	expect(process.process).to_not be_dead
end

Then /^(#{PROCESS}) should be failed/ do |process|
	expect(process.process).to be_failed
end

Then /^(#{PROCESS}) should not be failed/ do |process|
	expect(process.process).to_not be_failed
end

Then /^(#{PROCESS}) should be jammed/ do |process|
	expect(process.process).to be_jammed
end

Then /^(#{PROCESS}) should not be jammed/ do |process|
	expect(process.process).to_not be_jammed
end

Then /^(#{PROCESS}) exit code should be (\d+)$/ do |process, exit_code|
	expect(process.process.exit_code).to eq(exit_code.to_i)
end

Then /^(#{PROCESS}) readiness timeout should be (.*)/ do |process, seconds|
	expect(process.process.ready_timeout).to eq(seconds.to_f)
end

Then /^(#{PROCESS}) termination timeout should be (.*)/ do |process, seconds|
	expect(process.process.term_timeout).to eq(seconds.to_f)
end

Then /^(#{PROCESS}) kill timeout should be (.*)/ do |process, seconds|
	expect(process.process.kill_timeout).to eq(seconds.to_f)
end
