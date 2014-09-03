Feature: Running background processes
	Spawning of background process with ability to stop and restart.
	Logging to log file and pid file locking.
	Custom function can be passed to test if process is running

	Background:
		Given test background process executable is features/support/test_process
		Given bogus background process executable is features/support/bogus
		Given unkillable background process executable is features/support/test_process
		And unkillable process termination timeout is 0.0 second
		And unkillable process kill timeout is 0.0 second

	Scenario: Starting a background process
		Given test process is running
		And I wait 1 seconds for process to settle
		Then test process log should contain hello world
		Then test process should be running

	Scenario: Process dying after startup becomes dead
		Given bogus process is running
		And I wait 1 seconds for process to settle
		Then bogus process should not be running
		Then bogus process should be dead
		Then bogus exit code should be 1

	Scenario: Process failing to terminate becomes jammed
		Given unkillable process is running
		Then unkillable process should fail to stop
		Then unkillable process should be jammed

