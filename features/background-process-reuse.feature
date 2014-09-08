Feature: Background process reuse through different scenarios and features
	By default processes will be restarted for every scenario but this can be changed to keep them running.
	Custom refreshing can be set ups so that process state can be reset for every scenario without it's full restart.
	New processes will be spawned for different set of arguments required for given scenario.
	Pathname arguments will be checksumed to detect configuration changes as well.
	Process settings are reset for each scenario.

	Background:
		Given test background process ruby script is features/support/test_process

	@reuse @refreshing
	Scenario: Process is started once
		Given test process is running
		When we remember test process pid
		Given test process is running
		Then test process pid should be as remembered

	@reuse @refreshing
	Scenario: Explicit process refreshing
		Given test process is running
		When we remember test process pid
		Given test process is refreshed
		Then test process pid should be different than remembered

	@reuse @refreshing
	Scenario: Implicit process refreshing
		Given fresh test process is running
		When we remember test process pid
		Given fresh test process is running
		Then test process pid should be different than remembered

	@reuse @refreshing
	Scenario: Custom refresh command
		Given file /tmp/processtest1 does not exist
		Given test process is refreshed with command touch /tmp/processtest1
		Given test process is running
		When we remember test process pid
		And test process is refreshed
		Then file /tmp/processtest1 should exist
		Then test process pid should be as remembered

	@reuse @refreshing @reset
	Scenario: Custom refresh command is reset to default for each scenario
		Given file /tmp/processtest1 does not exist
		Given test process is refreshed with command touch /tmp/processtest1
		Given test process is running
		And test process is refreshed
		Then file /tmp/processtest1 should exist

	@reuse @refreshing @reset
	Scenario: Custom refresh command is reset to default for each scenario
		Given file /tmp/processtest1 does not exist
		And test process is running
		When we remember test process pid
		And test process is refreshed
		Then file /tmp/processtest1 should not exist
		Then test process pid should be different than remembered

	@reuse @arguments
	Scenario: New process started for different argument list
		Given test process is ready when log file contains hello world
		Given fresh test process is running and ready
		Then test process log should contain ARGV: []
		When we remember test process pid

	@reuse @arguments
	Scenario: New process started for different argument list
		Given test process is ready when log file contains hello world
		Given test process argument foo bar
		And test process is running and ready
		Then test process log should contain ARGV: ["foo bar"]
		And test process pid should be different than remembered

	@reuse @arguments @file
	Scenario: New process started for different argument list pointing to file with different content
		Given test process is ready when log file contains hello world
		Given test process file argument /tmp/processtest-config
		Given file /tmp/processtest-config content is foo bar
		And fresh test process is running and ready
		When we remember test process pid

	@reuse @arguments @file
	Scenario: New process started for different argument list pointing to file with different content
		Given test process is ready when log file contains hello world
		Given test process file argument /tmp/processtest-config
		Given file /tmp/processtest-config content is baz bar
		And test process is running and ready
		And test process pid should be different than remembered

	@reuse @arguments
	Scenario: Argument list is reset to default for each scenario
		Given test process is ready when log file contains hello world
		Given test process argument foo bar
		And fresh test process is running and ready
		Then test process log should contain ARGV: ["foo bar"]

	@reuse @arguments
	Scenario: Argument list is reset to default for each scenario
		Given test process is ready when log file contains hello world
		Given fresh test process is running and ready
		Then test process log should contain ARGV: []
