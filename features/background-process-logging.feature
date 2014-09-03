Feature: Handling of output and logging
	All process output is written to a log file.

	Background:
		Given test background process executable is features/support/test_process
		And test process is ready when log file contains hello world
		Given test2 background process executable is features/support/test_process
		And test2 process is ready when log file contains hello world

	@logging @output
	Scenario: Output from background process is logged to a log file
		Given test process argument foo bar
		And fresh test process is running and ready
		Then test process log should contain foo bar

