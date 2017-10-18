# OpenCensus - A stats collection and distributed tracing framework

This is the open-source release of Census for Ruby. Census provides a
framework to measure a server's resource usage and collect performance stats.
This repository contains Ruby related utilities and supporting software needed
by OpenCensus.

## Quick Start

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

## Tracing on Rack-based frameworks

The OpenCensus library for Ruby makes it easy to integrate OpenCensus tracing
into popular Rack-based Ruby web frameworks such as Ruby on Rails and
Sinatra. When the library integration is enabled, it automatically traces
incoming requests in the application.

### With Ruby on Rails

You can load the Railtie that comes with the library into your Ruby
on Rails application by explicitly requiring it during the application startup:

```ruby
# In config/application.rb
require "opencensus/trace/integrations/rails"
```

If you're using the `opencensus` gem, it automatically loads the Railtie into
your application when it starts.

### With other Rack-based frameworks

Other Rack-based frameworks, such as Sinatra, can use the Rack Middleware
provided by the library:

```ruby
require "opencensus/trace"
use OpenCensus::Trace::Integrations::RackMiddleware
```

### Adding Custom Trace Spans

The OpenCensus Rack Middleware automatically creates a trace record for
incoming requests. You can add additional custom trace spans within each
request:

```ruby
OpenCensus::Trace.in_span "my_task" do |span|
  # Do stuff...

  OpenCensus::Trace.in_span "my_subtask" do |subspan|
    # Do other stuff
  end
end
```

### Configuring the library

FIXME

## Supported Ruby Versions

This library is supported on Ruby 2.0+.

## Versioning

This library follows [Semantic Versioning](http://semver.org/).

It is currently in major version zero (0.y.z), which means that anything may
change at any time and the public API should not be considered stable.

## Contributing

Contributions to this library are always welcome and highly encouraged.

See the [Contributing Guide](CONTRIBUTING.md) for more information on how to get
started.

Please note that this project is released with a Contributor Code of Conduct. By
participating in this project you agree to abide by its terms. See
[Code of Conduct](CODE_OF_CONDUCT.md) for more information.

## License

This library is licensed under Apache 2.0. Full license text is available in
 [LICENSE](LICENSE).

 ## Disclaimer

 This is not an official Google product.
