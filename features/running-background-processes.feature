Feature: Running background processes
	Spawning of background process with ability to stop and restart.
	Logging to log file and pid file locking.
	Custom function can be passed to test if process is running

	Background:
		Given test background process executable is features/support/test_process
		Given bogus background process executable is features/support/bogus
		Given timeouts background process ruby script is features/support/test_process
		Given unkillable background process executable is features/support/test_process
		And unkillable process termination timeout is 0.0 second
		And unkillable process kill timeout is 0.0 second

	@running
	Scenario: Starting a background process
		Given test process is running
		And I wait 1 seconds for process to settle
		Then test process log should contain hello world
		Then test process should be running
		Then test process log should contain ENV['PROCESS_SPAWN_TYPE']: exec

	@running
	Scenario: Process dying after startup becomes dead
		Given bogus process is running
		And I wait 1 seconds for process to settle
		Then bogus process should not be running
		Then bogus process should be dead
		Then bogus process exit code should be 1

	@running @timeouts
	Scenario: Default time outs
		Then timeouts process readiness timeout should be 10
		And timeouts process termination timeout should be 10
		And timeouts process kill timeout should be 10

	@running @timeouts
	Scenario: Default time outs can be redefined
		Given timeouts process readiness timeout is 1.666 second
		And timeouts process termination timeout is 1.666 second
		And timeouts process kill timeout is 1.666 second
		Given fresh timeouts process is running
		Then timeouts process readiness timeout should be 1.666
		And timeouts process termination timeout should be 1.666
		And timeouts process kill timeout should be 1.666

	@running
	Scenario: Process failing to terminate becomes jammed
		Given unkillable process is running
		Then unkillable process should fail to stop
		Then unkillable process should be jammed

	@running @arguments
	Scenario: Specifying arguments
		Given test process is ready when log file contains hello world
		Given fresh test process is running and ready
		Then test process log should contain ARGV: []

	@running @arguments
	Scenario: Specifying arguments
		Given test process argument foo bar
		Given test process file argument /tmp/baz-bar
		Given test process option --hello with value foo baz
		Given test process option --conf with file value /tmp/bar
		Given test process is ready when log file contains hello world
		And test process is running and ready
		Then test process log should contain ARGV: ["foo bar", "/tmp/baz-bar", "--hello", "foo baz", "--conf", "/tmp/bar"]
