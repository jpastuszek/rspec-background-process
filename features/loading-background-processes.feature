Feature: Loading background processes
	Loading ruby scripts into running interpreter is faster than spawning new ruby process.
	This optimisation allows to load ruby script directly into forked process passing arguments via ENV['ARGV'].

	Background:
		Given test background process ruby script is features/support/test_process

	Scenario: Loading a background process
		Given test process is running
		And I wait 1 seconds for process to settle
		Then test process log should contain ENV['ARGV']

