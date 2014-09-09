Feature: Background processes are pooled for future reuse
	There is a limit on how many processes will be kept between scenarios.

	Background:
		Given test-1 background process ruby script is features/support/test_process
		Given test-2 background process ruby script is features/support/test_process
		Given test-3 background process ruby script is features/support/test_process
		Given test-4 background process ruby script is features/support/test_process
		Given test-5 background process ruby script is features/support/test_process

	@reuse @lru
	Scenario: Up to 4 most recently used processes are kept running between scenario but all within scenario using them
		Given test-1 process instance is running
		Given test-2 process instance is running
		Given test-3 process instance is running
		Given test-4 process instance is running
		Given test-5 process instance is running
		Then test-1 process instance should be running
		Then test-2 process instance should be running
		Then test-3 process instance should be running
		Then test-4 process instance should be running
		Then test-5 process instance should be running

	@reuse @lru
	Scenario: Up to 4 most recently used processes are kept running between scenario but all within scenario using them
		Then test-1 process instance should not be running
		Then test-2 process instance should be running
		Then test-3 process instance should be running
		Then test-4 process instance should be running
		Then test-5 process instance should be running
