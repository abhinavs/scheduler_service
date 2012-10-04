Scheduler Service
==================

Scheduler Service is a JSON web service for invoking delayed triggers or jobs through callback URLs.

Quick Intro
------------
Once up and running, your clients can call this service with two parameters - callback\_url and scheduled\_for time. It will invoke the callback\_url at the scheduled time.

Here is how you will do call the service in Ruby:

``` ruby
require 'rest_client'
require 'json'

# call example.com after 5 minutes from now
RestClient.post "http://service_server_name/jobs/new", { :url => "http://www.example.com", :callback_at => Time.now.utc + 300 }.to_json,
:content_type => :json, :accept => :json
```

Stack
-----

* Sinatra
* MongoDB

