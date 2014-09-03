Feature: Background process readiness verification
	Spawning of background process with additional verification before considering it ready.

	Background:
		Given test background process executable is features/support/test_process
		Given timeout background process executable is features/support/test_process
		Given timeout process readiness timeout is 0.1 second

	Scenario: Starting a background process with readiness check
		Given test process is ready when log file contains hello world
		And test process is running and ready
		Then test process should be running
		Then test process should be ready
		Then test process log should contain hello world

	Scenario: Starting process failing to become ready on time
		Given timeout process is ready when log file contains ready
		And timeout process is running
		Then timeout process should fail to become ready in time
		Then timeout process should not be running
		Then timeout process should be failed

