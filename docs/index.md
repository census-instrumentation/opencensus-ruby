---
# You don't need to edit this file, it's empty on purpose.
# Edit theme's home layout instead if you wanna make some changes
# See: https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: default
---

# OpenCensus for Ruby

## Installation

1. Add `opencensus` to your `Gemfile`:

    ```ruby
    gem "opencensus"
    ```

1. Use `bundler` to install the gem:

    ```bash
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
