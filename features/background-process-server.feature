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
		Then http-singleport process instance should have port 12000 allocated

	@server @port
	Scenario: New server instances get next port number allocated
		Then http-singleport process instance should have port 12000 allocated

	@server @port
	Scenario: New server instances get next port number allocated
		Given http-singleport process argument foo bar
		Then http-singleport process instance should have port 12001 allocated

	@server @port @multiport
	Scenario: New server instances get next set of ports number allocated
		Then http-multiport process instance should have port 14000, 14001, 14002, 14003 allocated

	@server @port @multiport
	Scenario: New server instances get next set of ports number allocated
		Given http-multiport process argument foo bar
		Then http-multiport process instance should have port 14004, 14005, 14006, 14007 allocated

	@server @port @passing
	Scenario: Passing port numbers to process arguments
		Given http-1 background process ruby script is features/support/test_http_server
		And http-1 process is a server with 2 port allocated from 15000 up
		And http-1 process is ready when log file contains starting
		Given http-1 process option --listen with value localhost:<allocated port 1>
		And http-1 process instance is running and ready
		Then http-1 process instance log should contain listening on port: 15000

		Given http-2 background process ruby script is features/support/test_http_server
		And http-2 process is a server with 2 port allocated from 16000 up
		And http-2 process is ready when log file contains starting
		Given http-2 process option --listen with value localhost:<allocated port 2>
		And http-2 process instance is running and ready
		Then http-2 process instance log should contain listening on port: 16001

	@server @port @passing
	Scenario: Passing port numbers to log file ready
		Given http-ready background process ruby script is features/support/test_http_server
		And http-ready process is a server with 2 port allocated from 15100 up
		Given http-ready process option --listen with value localhost:<allocated port 1>
		And http-ready process is ready when log file contains localhost:<allocated port 1>
		And http-ready process instance is running and ready
		Then http-ready process instance log should contain listening on port: 15100

	@server @port @passing
	Scenario: Passing port numbers to refresh command
		Given file /tmp/processtest213 does not exist
		Given http-refresh background process ruby script is features/support/test_http_server
		And http-refresh process is a server with 2 port allocated from 15213 up
		And http-refresh process is ready when log file contains listening on port
		Given http-refresh process option --listen with value localhost:<allocated port 1>
		Given http-refresh process is refreshed with command echo '<allocated port 1>' > /tmp/processtest213
		And http-refresh process instance is running and ready
		Given http-refresh process instance is refreshed
		Then file /tmp/processtest213 should contain 15213

	@server @port @passing
	Scenario: URL readiness check can replace port number with given port
		Given http-run process option --listen with value localhost:<allocated port 1>
		Given http-run process is ready when URI http://localhost:<allocated port 1>/health_check response status is OK
		And http-run process instance is running and ready
