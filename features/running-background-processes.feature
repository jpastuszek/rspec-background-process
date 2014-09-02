Feature: Running background processes
	Spawning of background process with ability to stop and restart.
	Logging to log file and pid file locking.
	Custom function can be passed to test if process is running

	Background:
		Given test background process executable is features/support/test_process
		Given test2 background process executable is features/support/test_process
		Given start-fail background process executable is features/support/test_start_fail

	Scenario: Starting a background process
		Given test process is running
		And I wait 1 seconds for process to settle
		Then test process log should contain hello world
		Then test process should be running

	Scenario: Starting a background process with readiness check
		Given test process is ready when log file contains hello world
		And test process is running
		Then test process should be running
		Then test process should be ready
		Then test process log should contain hello world

	Scenario: Starting a background process with readiness check timeout
		Given test process is ready when log file contains ready
		And test process is running
		Then test process log should contain ready
		Then test process should be ready
		Given test2 process readiness timeout is 0.1 second
		And test2 process is ready when log file contains ready
		Then test2 process should fail to start in time
		Then test2 process should not be running

	Scenario: Process is started once
		Given test process is ready when log file contains hello world
		And test process is running
		And we remember test process pid
		Given test process is ready when log file contains ready
		And test process is running
		Then test process log should contain ready
		And test process pid should be as remembered

	Scenario: Process refreshing
		Given test process is ready when log file contains hello world
		And test process is running
		And we remember test process pid
		Given test process is ready when log file contains ready
		And test process is refreshed
		Then test process log should contain ready
		And test process pid should be different than remembered

	Scenario: Process failing to start
		Given start-fail process is ready when log file contains hello world
		Given start-fail process exits prematurely
		Then start-fail exit code should be 2
		Then start-fail process should not be running

