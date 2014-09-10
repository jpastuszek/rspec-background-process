Feature: Background process readiness verification
	Spawning of background process with additional verification before considering it ready.

	Background:
		Given test-ok background process ruby script is features/support/test_process
		Given test-ok process is ready when log file contains started

	@readiness @log
	Scenario: Starting a background process with readiness check based on log file contents
		And test-ok process instance is running and ready
		Then test-ok process instance should be running
		Then test-ok process instance should be ready
		Then test-ok process instance log should contain started

	@readiness @failed
	Scenario: Starting process failing to become ready on time
		Given test-timeout background process ruby script is features/support/test_process
		Given test-timeout process readiness timeout is 0.1 second
		Given test-timeout process is ready when log file contains started
		And test-timeout process instance is running
		Then test-timeout process instance should fail to become ready in time
		Then test-timeout process instance should not be running
		Then test-timeout process instance should be failed

	@readiness @failed
	Scenario: Starting process failing readiness test with falsy value
		Given test-falsy background process ruby script is features/support/test_process
		Given test-falsy process readiness fails with falsy value
		And test-falsy process instance is running
		Then test-falsy process instance should fail to become ready with failed error
		Then test-falsy process instance should not be running
		Then test-falsy process instance should be failed

	@readiness @failed
	Scenario: Starting process failing readiness test with exception
		Given test-exception background process ruby script is features/support/test_process
		Given test-exception process readiness fails with exception
		And test-exception process instance is running
		Then test-exception process instance should fail to become ready with exceptionr
		Then test-exception process instance should not be running
		Then test-exception process instance should be failed

	@readiness @reset
	Scenario: Readiness check is reset to default for each scenario
		Given test-ok process is ready when log file contains hello world
		And fresh test-ok process instance is running and ready
		Then test-ok process instance should be ready
		Then test-ok process instance log should contain hello world
		Then test-ok process instance log should not contain started
		When we remember test-ok process instance pid

	@readiness @reset
	Scenario: Readiness check is reset to default for each scenario
		And test-ok process instance is running
		And test-ok process instance is verified
		Then test-ok process instance log should contain started
		Then test-ok process instance pid should be as remembered

	@readiness @http
	Scenario: Starting a background process with readiness check based on HTTP request
		Given http background process ruby script is features/support/test_http_server
		Given http process is ready when URI http://localhost:1234/health_check response status is OK
		And http process instance is running
		Then http process instance log should not contain "GET /health_check HTTP/1.1" 200
		Given http process instance is ready
		Then http process instance log should contain "GET /health_check HTTP/1.1" 200
