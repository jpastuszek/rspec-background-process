Feature: Running background processes
	Spawning of background process with ability to stop and restart.
	Logging to log file and pid file locking.
	Custom function can be passed to test if process instance is running

	Background:
		Given test background process executable is features/support/test_process
		Given timeouts background process ruby script is features/support/test_process

	@running
	Scenario: Starting a background process
		Given test process instance is running
		And I wait 1 seconds for process instance to settle
		Then test process instance log should contain hello world
		Then test process instance should be running
		Then test process instance log should contain ENV['PROCESS_SPAWN_TYPE']: exec

	@running
	Scenario: Process dying after startup becomes dead
		Given bogus background process executable is features/support/bogus
		Given bogus process instance is running
		And I wait 1 seconds for process to settle
		Then bogus process instance should not be running
		Then bogus process instance should be dead
		Then bogus process instance exit code should be 1

	@running @timeouts
	Scenario: Default time outs
		Then timeouts process instance readiness timeout should be 10 seconds
		And timeouts process instance termination timeout should be 10 seconds
		And timeouts process instance kill timeout should be 10 seconds

	@running @timeouts
	Scenario: Custom time outs
		Given timeouts process readiness timeout is 1.666 second
		And timeouts process termination timeout is 1.666 second
		And timeouts process kill timeout is 1.666 second
		Given fresh timeouts process instance is running
		Then timeouts process instance readiness timeout should be 1.666 second
		And timeouts process instance termination timeout should be 1.666 second
		And timeouts process instance kill timeout should be 1.666 second

	@running @timeouts @reset
	Scenario: Time outs are reset to default for each scenario
		Given timeouts process readiness timeout is 1.666 second
		And timeouts process termination timeout is 1.666 second
		And timeouts process kill timeout is 1.666 second
		Given fresh timeouts process instance is running
		Then timeouts process instance readiness timeout should be 1.666 second
		And timeouts process instance termination timeout should be 1.666 second
		And timeouts process instance kill timeout should be 1.666 second
		When we remember timeouts process instance pid

	@running @timeouts @reset
	Scenario: Time outs are reset to default for each scenario
		Then timeouts process instance readiness timeout should be 10 second
		And timeouts process instance termination timeout should be 10 second
		And timeouts process instance kill timeout should be 10 second
		Then timeouts process instance pid should be as remembered

	@running
	Scenario: Process failing to terminate becomes jammed
		Given unkillable background process executable is features/support/test_process
		And unkillable process termination timeout is 0.0 second
		And unkillable process kill timeout is 0.0 second
		Given unkillable process instance is running
		Then unkillable process instance should fail to stop
		Then unkillable process instance should be jammed

	@running @arguments
	Scenario: Specifying arguments
		Given test process is ready when log file contains hello world
		Given fresh test process instance is running and ready
		Then test process instance log should contain ARGV: []

	@running @arguments
	Scenario: Specifying arguments
		Given test process argument foo bar
		Given test process file argument /tmp/baz-bar
		Given test process option --hello with value foo baz
		Given test process option --conf with file value /tmp/bar
		Given test process is ready when log file contains hello world
		And test process instance is running and ready
		Then test process instance log should contain ARGV: ["foo bar", "/tmp/baz-bar", "--hello", "foo baz", "--conf", "/tmp/bar"]
