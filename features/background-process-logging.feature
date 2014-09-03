Feature: Handling of output and logging

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

	@logging @cwd
	Scenario: By default process is started in unique temporary directory
		Given fresh test process is running and ready
		When we remember test process reported current directory
		Given fresh test2 process is running and ready
		Then remembered process current directory is different from test2 process reported one

	@logging @cwd
	Scenario: Process current directory changes does not affect our test current directory
		Given we remember current working directory
		And fresh test process is running and ready
		Then current working directory is unchanged

	@logging @cwd
	Scenario: Process current working directory configurable to current working directory
		Given we remember current working directory
		Given test process working directory is the same as current working directory
		Given fresh test process is running and ready
		Then current working directory is unchanged
		Then test process reports it's current working directory to be the same as current directory

	@logging @cwd
	Scenario: The current working directory should be configurable to provided directory
		Given test process working directory is changed to tmp/test
		Given fresh test process is running and ready
		Then test process reports it's current working directory to be relative to current working directory by tmp/test

