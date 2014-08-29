Feature: Spawning of background process
	Spawning of background process with ability to stop and restart.
	Logging to log file and pid file locking.
	Custom function can be passed to test if process is running

	Background:
		Given test background process executable is features/support/test_process

	Scenario: Starting a background process
		Given test process is running
		And I wait 0.4 seconds for process to settle
		Then test process log should contain hello world

	Scenario: Starting a background process with readiness check
		Given test process is ready when log file contains hello world
		Given test process is running
		Then test process log should contain hello world
