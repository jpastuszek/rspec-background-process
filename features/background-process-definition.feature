Feature: Defining background process
	Background:
		Given test background process executable is features/support/test_process
		Given test process is ready when log file contains started

	@defining
	Scenario: Defining process executable
		Given fresh test process is running and ready
		Then test process log should contain hello world
		Then test process log should not contain foo bar

		Given test2 background process executable is features/support/test_process2
		Given test2 process is ready when log file contains started
		Given fresh test2 process is running and ready
		Then test2 process log should contain foo bar
		Then test2 process log should not contain hello world

	@defining @redefining
	Scenario: Defining process twice in one scenario is not allowed
		Then defining test background process again should fail

	@defining @changes
	Scenario: Once instance is created from definition it cannot be modified
		Given fresh test process is running
		Then following steps should fail with RuntimeError: can't modify frozen Hash
			| test process is refreshed with command touch /tmp/processtest1 |
			| test process is ready when log file contains started |
			| test process readiness timeout is 1.666 second |
			| test process termination timeout is 1.666 second |
			| test process kill timeout is 1.666 second |
		Then following steps should fail with RuntimeError: can't modify frozen Array
			| test process argument foo bar |
			| test process file argument /tmp/baz-bar |
			| test process option --hello with value foo baz |
			| test process option --conf with file value /tmp/bar |
		Then following steps should fail with RuntimeError: can't modify frozen Hash
			| test process is a server with 1 port allocated from 666 up |
