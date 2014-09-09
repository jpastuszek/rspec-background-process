Feature: Loading background processes
	Loading ruby scripts into running interpreter is faster than spawning new ruby process.
	This optimisation allows to load ruby script directly into forked process passing arguments via ENV['ARGV'].

	Background:
		Given loaded background process ruby script is features/support/test_process

	@loading
	Scenario: Loading a background process
		Given loaded process instance is running
		And I wait 1 seconds for process instance to settle
		Then loaded process instance log should contain ENV['PROCESS_SPAWN_TYPE']: load

	@loading @arguments
	Scenario: Loaded process receives arguments as usual (emulated)
		Given loaded process is ready when log file contains hello world
		Given loaded process argument foo bar
		Given loaded process argument baz
		And loaded process instance is running and ready
		Then loaded process instance log should contain ARGV: ["foo bar", "baz"]
		Then loaded process instance log should match \$0: .*features/support/test_process
		Then loaded process instance log should contain $*: ["foo bar", "baz"]
