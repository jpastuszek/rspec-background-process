Feature: Running background processes
	Spawning of background process with ability to stop and restart.
	Logging to log file and pid file locking.
	Custom function can be passed to test if process is running

	Background:
		Given test background process executable is features/support/test_process
		Given bogus background process executable is features/support/bogus

	Scenario: Starting a background process
		Given test process is running
		And I wait 1 seconds for process to settle
		Then test process log should contain hello world
		Then test process should be running

	Scenario: Process is started once
		And test process is running
		And we remember test process pid
		And test process is running
		And test process pid should be as remembered

	Scenario: Process refreshing
		And test process is running
		And we remember test process pid
		And test process is refreshed
		And test process pid should be different than remembered

	Scenario: Process failing to start
		Given bogus process is running
		And I wait 1 seconds for process to settle
		Then bogus process should not be running
		Then bogus process should be dead
		Then bogus exit code should be 1
