Feature: Cloning defined process
	Sometimes we just want to change one aspect of already defined process with possibly running instance.

	Scenario: Cloning process definition with new argument and different readiness test
		Given source background process ruby script is features/support/test_process
		Given source process argument foo bar
		And source process is ready when log file contains hello world

		Given clone background process is based on source process definition
		Given clone process argument baz
		And clone process is ready when log file contains started

		And source process instance is running and ready
		Then source process instance should be ready
		Then source process instance log should contain foo bar
		Then source process instance log should not contain baz
		Then source process instance log should not contain started

		And clone process instance is running and ready
		Then clone process instance should be ready
		Then clone process instance log should contain foo bar
		Then clone process instance log should contain baz
		Then clone process instance log should contain started
