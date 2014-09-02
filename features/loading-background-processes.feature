Feature: Loading background processes
	Loading ruby scripts into running interpreter is faster than spawning new ruby process.
	This optimisation allows to load ruby script directly into forked process passing arguments via ENV['ARGV'].

	Background:
		Given loaded background process ruby script is features/support/test_process

	Scenario: Loading a background process
		Given loaded process is running
		And I wait 1 seconds for process to settle
		Then loaded process log should contain ENV['ARGV']

