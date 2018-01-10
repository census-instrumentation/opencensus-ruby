---
layout: default
---

# OpenCensus for Ruby

OpenCensus provides a framework to measure a server's resource usage and
collect performance stats. The `opencensus` Rubygem contains the core
OpenCensus APIs and basic integrations with Rails, Faraday, and GRPC.

The library is in alpha stage, and the API is subject to change.

## Quick Start

### Installation

Install the gem directly:

```sh
$ gem install opencensus
```

Or install through Bundler:

1. Add the `opencensus` gem to your Gemfile:

```ruby
gem "opencensus"
```

2. Use Bundler to install the gem:

```sh
$ bundle install
```

### Getting started with Ruby on Rails

The OpenCensus library provides a Railtie that integrates with Ruby On Rails,
automatically tracing incoming requests in the application. It also
automatically traces key processes in your application such as database queries
and view rendering.

To enable Rails integration, require this file during application startup:

```ruby
# In config/application.rb
require "opencensus/trace/integrations/rails"
```

### Getting started with other Rack-based frameworks

Other Rack-based frameworks, such as Sinatra, can use the Rack Middleware
integration, which automatically traces incoming requests. To enable the
integration for a non-Rails Rack framework, add the middleware to your
middleware stack.

```ruby
# In config.ru or similar Rack configuration file
require "opencensus/trace/integrations/rack_middleware"
use OpenCensus::Trace::Integrations::RackMiddleware
```

## Instrumentation features

### Tracing outgoing HTTP requests

If your app uses the [Faraday](https://github.com/lostisland/faraday) library
to make outgoing HTTP requests, consider installing the Faraday Middleware
integration. This integration creates a span for each outgoing Faraday request,
tracking the latency of that request, and propagates distributed trace headers
into the request so you can potentially connect your request trace with that of
the remote service. Here is an example:

```ruby
conn = Faraday.new(url: "http://www.example.com") do |c|
  c.use OpenCensus::Trace::Integrations::FaradayMiddleware
  c.adapter Faraday.default_adapter
  end
conn.get "/"
```

See the documentation for the
[FaradayMiddleware](http://opencensus.io/opencensus-ruby/api/OpenCensus/Trace/Integrations/FaradayMiddleware.html)
class for more info.

### Adding Custom Trace Spans

In addition to the spans added by the Rails integration (e.g. for database
queries) and by Faraday integration for outgoing HTTP requests, you can add
additional custom spans to the request trace:

```ruby
OpenCensus::Trace.in_span "my_task" do |span|
  # Do stuff...

  OpenCensus::Trace.in_span "my_subtask" do |subspan|
    # Do other stuff
  end
end
```

See the documentation for the
[OpenCensus::Trace](http://opencensus.io/opencensus-ruby/api/OpenCensus/Trace.html)
module for more info.

### Exporting traces

By default, OpenCensus will log request trace data as JSON. To export traces to
your favorite analytics backend, install an export plugin. There are plugins
currently being developed for Stackdriver, Zipkin, and other services.

### Configuring the library

OpenCensus allows configuration of a number of aspects via the configuration
class. The following example illustrates how that looks:

```ruby
OpenCensus.configure do |c|
  c.trace.default_sampler = OpenCensus::Trace::Samplers::AlwaysSample.new
  c.trace.default_max_attributes = 16
end
```

If you are using Rails, you can equivalently use the Rails config:

```ruby
config.opencensus.trace.default_sampler =
  OpenCensus::Trace::Samplers::AlwaysSample.new
config.opencensus.trace.default_max_attributes = 16
```

You can configure a variety of core OpenCensuys options, including:

* Sampling, which controls how often a request is traced.
* Exporting, which controls how trace information is reported.
* Formatting, which controls how distributed request trace headers are
  constructed
* Size maximums, which control when trace data is truncated.

Additionally, integrations and other plugins might have their own
configurations.

For more information, consult the documentation for
[OpenCensus.configure](http://opencensus.io/opencensus-ruby/api/OpenCensus.html#configure-class_method)
and
[OpenCensus::Trace.configure](http://opencensus.io/opencensus-ruby/api/OpenCensus/Trace.html#configure-class_method).

## Supported Ruby Versions

This library is supported on Ruby 2.0+.
