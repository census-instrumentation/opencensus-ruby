# Release History

### 0.3.1 / 2018-04-13

* Clean unneeded files from the gem

### 0.3.0 / 2018-03-26

* SpanContext#build_contained_spans honors sampling bit.
* Use AlwaysSample as the default sampler.
* Support the Span.kind field.

### 0.2.2 / 2018-03-09

* Railtie now adds the middleware at the end of the stack by default, and provides a config that can customize the position
* Provided a multi exporter
* Document exporter interface
* Fix some broken links in the documentation

### 0.2.1 / 2018-03-05

* Clarify Ruby version requirement (2.2+)
* Fix exceptions in the config library on Ruby 2.2 and 2.3.
* Automatically require opencensus base library from standard integrations.

### 0.2.0 / 2018-02-13

* Span creation sets the "same_process_as_parent_span" field if possible.
* The "stack_trace_hash_id" field was missing from the interfaces. Fixed.
* Nullability of a few fields did not match the proto specs. Fixed.
* Fixed some documentation errors and omissions.

### 0.1.0 / 2018-01-12

Initial release of the core library, including:

* Trace interfaces
* Rack integration
* Rails integration
* Faraday integration
* Logging exporter
