Feature: Server process with port allocation
	Pooled background server processes needs port numbers managed to avoid collisions.

	Background:
		Given http-singleport background process ruby script is features/support/test_http_server
		Given http-singleport process is a server with 1 port allocated from 12000 up

		Given http-multiport background process ruby script is features/support/test_http_server
		Given http-multiport process is a server with 4 port allocated from 14000 up

		Given http-run background process ruby script is features/support/test_http_server
		Given http-run process is a server with 1 port allocated from 17000 up

	@server @port
	Scenario: Server instance gets given port allocated
		Then http-singleport process should have port 12000 allocated

	@server @port
	Scenario: New server instances get next port number allocated
		Then http-singleport process should have port 12000 allocated

	@server @port
	Scenario: New server instances get next port number allocated
		Given http-singleport process argument foo bar
		Then http-singleport process should have port 12001 allocated

	@server @port @multiport
	Scenario: New server instances get next set of ports number allocated
		Then http-multiport process should have port 14000, 14001, 14002, 14003 allocated

	@server @port @multiport
	Scenario: New server instances get next set of ports number allocated
		Given http-multiport process argument foo bar
		Then http-multiport process should have port 14004, 14005, 14006, 14007 allocated

	@server @port @passing
	Scenario: Passing port numbers to process arguments
		Given http-1 background process ruby script is features/support/test_http_server
		And http-1 process is a server with 2 port allocated from 15000 up
		And http-1 process is ready when log file contains starting
		Given http-1 process option --listen with value localhost:<allocated port 1>
		And http-1 process is running and ready
		Then http-1 process log should contain listening on port: 15000

		Given http-2 background process ruby script is features/support/test_http_server
		And http-2 process is a server with 2 port allocated from 16000 up
		And http-2 process is ready when log file contains starting
		Given http-2 process option --listen with value localhost:<allocated port 2>
		And http-2 process is running and ready
		Then http-2 process log should contain listening on port: 16001

	@server @port @passing
	Scenario: URL readiness check can replace port number with given port
		Given http-run process option --listen with value localhost:<allocated port 1>
		Given http-run process is ready when URI http://localhost:<allocated port 1>/health_check response status is OK
		And http-run process is running and ready
