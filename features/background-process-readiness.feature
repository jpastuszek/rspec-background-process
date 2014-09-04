Feature: Background process readiness verification
	Spawning of background process with additional verification before considering it ready.

	Background:
		Given test-ok background process ruby script is features/support/test_process
		Given test-timeout background process ruby script is features/support/test_process
		Given test-timeout process readiness timeout is 0.1 second
		Given test-falsy background process ruby script is features/support/test_process
		Given test-exception background process ruby script is features/support/test_process
		Given http background process ruby script is features/support/test_http_server

	@readiness @log
	Scenario: Starting a background process with readiness check based on log file contents
		Given test-ok process is ready when log file contains started
		And test-ok process is running and ready
		Then test-ok process should be running
		Then test-ok process should be ready
		Then test-ok process log should contain started

	@readiness @failed
	Scenario: Starting process failing to become ready on time
		Given test-timeout process is ready when log file contains started
		And test-timeout process is running
		Then test-timeout process should fail to become ready in time
		Then test-timeout process should not be running
		Then test-timeout process should be failed

	@readiness @failed
	Scenario: Starting process failing readiness test with falsy value
		Given test-falsy process readiness fails with falsy value
		And test-falsy process is running
		Then test-falsy process should fail to become ready with failed error
		Then test-falsy process should not be running
		Then test-falsy process should be failed

	@readiness @failed
	Scenario: Starting process failing readiness test with exception
		Given test-exception process readiness fails with exception
		And test-exception process is running
		Then test-exception process should fail to become ready with exception
		Then test-exception process should not be running
		Then test-exception process should be failed

	@readiness @http
	Scenario: Starting a background process with readiness check based on HTTP request
		Given http process is ready when URI http://localhost:1234/health_check response status is OK
		And http process is running
		Then http process log should not contain "GET /health_check HTTP/1.1" 200
		Given http process is ready
		Then http process log should contain "GET /health_check HTTP/1.1" 200
