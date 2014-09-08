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
		Given test-1 process is running
		Given test-2 process is running
		Given test-3 process is running
		Given test-4 process is running
		Given test-5 process is running
		Then test-1 process should be running
		Then test-2 process should be running
		Then test-3 process should be running
		Then test-4 process should be running
		Then test-5 process should be running

	@reuse @lru
	Scenario: Up to 4 most recently used processes are kept running between scenario but all within scenario using them
		Then test-1 process should not be running
		Then test-2 process should be running
		Then test-3 process should be running
		Then test-4 process should be running
		Then test-5 process should be running
