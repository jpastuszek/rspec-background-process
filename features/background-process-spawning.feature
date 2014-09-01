Feature: Spawning of background process
	Spawning of background process with ability to stop and restart.
	Logging to log file and pid file locking.
	Custom function can be passed to test if process is running

	Background:
		Given test background process executable is features/support/test_process
		Given test2 background process executable is features/support/test_process
		Given test-loaded background process ruby script is features/support/test_process

	Scenario: Starting a background process
		Given test process is running
		And I wait 1 seconds for process to settle
		Then test process log should contain hello world

	Scenario: Starting a background process with readiness check
		Given test process is ready when log file contains hello world
		And test process is running
		Then test process log should contain hello world

	Scenario: Starting a background process with readiness check timeout
		Given test process is ready when log file contains ready
		And test process is running
		Then test process log should contain ready
		Given test2 process readiness timeout is 0.1 second
		And test2 process is ready when log file contains ready
		Then test2 process should fail to start in time

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

	Scenario: Loading a background process
		Given test-loaded process is running
		And I wait 1 seconds for process to settle
		Then test-loaded process log should contain ENV['ARGV']

