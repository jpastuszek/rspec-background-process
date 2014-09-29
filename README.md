# rspec-background-process

RSpec and Cucumber DSL that allows definition of processes with their arguments, working directory, time outs, port numbers etc. and start/stop them during test runs.
Processes with same definitions can be pooled and reused between example runs to save time on startup/shutdown. Pooling supports limiting the number of running processes with LRU to limit memory used.

## Example Usage

```ruby
background_process('bin/http-worker').with do |process|
	process.http_port_allocated_form 1200

	process.argument '--listen', '127.0.0.1:<allocated port 1>'
	process.argument '--foreground'
	process.argument '--debug'

	process.ready_when_log_includes 'worker=0 ready'
end
.start
.wait_ready
```

The above example will start up (or reuse) instance of `http-worker` process with given arguments and allocated unique port number. 
The `#wait_ready` method will return after process logs `worker=0 ready` to standard output or error. This way the process has a chance of starting up fully before we continue with testing.

## Usage with RSpec

Add `require 'rspec-background-process'` to your `spec_helper.rb` and use `with: :background_process` meta tag on example groups that will use `#backgroud_process`.

```ruby
require_relative 'spec_helper'

describe 'starting background process', with: :background_process do
	before :all do
		background_process('bin/test_process').with do |process|
			process.ready_when_log_includes 'ready'
		end
		.start
		.wait_ready
	end

	example 'test with process running in background' do
	end
end
```

## Usage with Cucumber

Add `require 'rspec-background-process'` to your `env.rb`.

```ruby
Given /^my server is running$/ do
	@server = background_process('bin/server', load: true).with do |process|
		process.http_port_allocated_form 1200

		process.argument '--listen', '127.0.0.1:<allocated port 1>'
		process.argument '--dump-log-at-exit'
		process.argument '--working-directory', '<working directory>'
		process.argument '--config-prepend', '<project directory>/etc/server.conf'

		process.ready_when_url_response_status 'http://localhost:<allocated port 1>/health.test', 'OK'

		process.refresh_action do |instance|
			open(instance.render('http://127.0.0.1:<allocated port 1>/_purge'))
		end
	end
end
```

## More info

See spec files for more usage options.

## Contributing to rspec-background-process

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 Global Medical Treatment Ltd trading as WhatClinic.com. 
See LICENSE.txt for further details.
