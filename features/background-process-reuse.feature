Feature: Background process reuse through different scenarios and features
	By default processes will be restarted for every scenario but this can be changed to keep them running.
	Custom refreshing can be set ups so that process state can be reset for every scenario without it's full restart.
	New processes will be spawned for different set of arguments required for given scenario.
	Pathname arguments will be checksumed to detect configuration changes as well.
	Process settings are reset for each scenario.

	Background:
		Given test background process executable is features/support/test_process
		Given timeouts background process executable is features/support/test_process
		And timeouts process readiness timeout is 1.42 second
		And timeouts process termination timeout is 1.42 second
		And timeouts process kill timeout is 1.42 second
		Given ready background process executable is features/support/test_process
		Given ready process is ready when log file contains ready

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
	Scenario: Custom refresh method
		Given file /tmp/processtest1 does not exist
		And fresh test process is running
		Then file /tmp/processtest1 should not exist
		When we remember test process pid
		Given test process is refreshed with command touch /tmp/processtest1
		And fresh test process is running
		Then file /tmp/processtest1 should exist
		And test process pid should be as remembered

	@reuse @refreshing
	Scenario: Default refresh method restored for each scenario
		And test process is running
		Given file /tmp/processtest1 does not exist
		Given test process is refreshed with command touch /tmp/processtest1
		And fresh test process is running
		Then file /tmp/processtest1 should exist

	@reuse @refreshing
	Scenario: Default refresh method restored for each scenario
		Given test process is running
		And file /tmp/processtest1 does not exist
		When we remember test process pid
		And fresh test process is running
		Then file /tmp/processtest1 should not exist
		And test process pid should be different than remembered

	@reuse @options
	Scenario: Default time outs are restored for each scenario
		Given fresh timeouts process is running
		And timeouts process readiness timeout is 1.666 second
		And timeouts process termination timeout is 1.666 second
		And timeouts process kill timeout is 1.666 second
		Then timeouts process readiness timeout should be 1.666
		And timeouts process termination timeout should be 1.666
		And timeouts process kill timeout should be 1.666

	@reuse @options
	Scenario: Default time outs are restored for each scenario
		Given timeouts process is running
		Then timeouts process readiness timeout should be 1.42
		And timeouts process termination timeout should be 1.42
		And timeouts process kill timeout should be 1.42

	@reuse @readiness
	Scenario: Readiness check is reset to default for each scenario
		Given ready process is ready when log file contains hello world
		And fresh ready process is running and ready
		Then ready process should be ready
		Then ready process log should contain hello world
		Then ready process log should not contain ready

	@reuse @readiness
	Scenario: Readiness check is reset to default for each scenario
		And ready process is running and ready
		Then ready process should be ready
		Then ready process log should contain ready

	@reuse @arguments
	Scenario: New process started for each argument list
		Given test process is ready when log file contains hello world
		Given fresh test process is running and ready
		Then test process log should contain ARGV: []
		When we remember test process pid
		Given test process argument foo bar
		And test process is running and ready
		Then test process log should contain ARGV: ["foo bar"]
		And test process pid should be different than remembered

	@reuse @arguments
	Scenario: New process started for each argument list pointing to file with different content
		Given test process is ready when log file contains hello world
		Given test process file argument /tmp/processtest-config
		Given file /tmp/processtest-config content is foo bar
		And fresh test process is running and ready
		When we remember test process pid
		Given file /tmp/processtest-config content is baz bar
		And test process is running and ready
		And test process pid should be different than remembered

	@reuse @arguments
	Scenario: Argument list is reset to default for each scenario
		Given test process is ready when log file contains hello world
		Given fresh test process is running and ready
		Then test process log should contain ARGV: []
		Given test process argument foo bar
		And fresh test process is running and ready
		Then test process log should contain ARGV: ["foo bar"]

	@reuse @arguments
	Scenario: Argument list is reset to default for each scenario
		Given test process is ready when log file contains hello world
		Given fresh test process is running and ready
		Then test process log should contain ARGV: []
