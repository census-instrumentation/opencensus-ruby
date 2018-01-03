# Copyright 2017 OpenCensus Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "faraday"

module OpenCensus
  module Trace
    module Integrations
      ##
      # # Faraday integration
      #
      # This is a middleware for the Faraday HTTP client:
      #
      # * It wraps all outgoing requests in spans
      # * It adds the trace context to outgoing requests.
      #
      # Example:
      #
      #     conn = Faraday.new(url: "http://www.example.com") do |c|
      #       c.use OpenCensus::Trace::Integrations::FaradayMiddleware,
      #             span_name: "http request"
      #       c.adapter Faraday.default_adapter
      #     end
      #     conn.get "/"
      #
      # ## Configuring spans
      #
      # By default, spans are added to the thread-local span context, as if
      # by calling `OpenCensus::Trace.start_span`. If there is no span context,
      # then no span is added and this middleware effectively disables itself.
      #
      # You may also provide a span context, by passing it in the middleware
      # options hash. For example:
      #
      #     conn = Faraday.new(url: "http://www.example.com") do |c|
      #       c.use OpenCensus::Trace::Integrations::FaradayMiddleware,
      #             span_context: my_span_context
      #       c.adapter Faraday.default_adapter
      #     end
      #
      # You may also override the span context for a particular request by
      # including it in the options:
      #
      #     conn.get do |req|
      #       req.url "/"
      #       req.options.context = { span_context: my_span_context }
      #     end
      #
      # By default, all spans are given a default name. You may also override
      # this by passing a `:span_name` in the middleware options hash and/or
      # the request options.
      #
      # ## Trace context
      #
      # This currently adds a header to each outgoing request, propagating the
      # trace context for distributed tracing. By default, this uses the
      # TraceContext formatter.
      #
      # You may provide your own implementation of the formatter by configuring
      # it in the middleware options hash. For example:
      #
      #     conn = Faraday.new(url: "http://www.example.com") do |c|
      #       c.use OpenCensus::Trace::Integrations::FaradayMiddleware,
      #             formatter: OpenCensus::Trace::Formatters::CloudTrace.new
      #       c.adapter Faraday.default_adapter
      #     end
      #
      # You many also override the formatter for a particular request by
      # including it in the options:
      #
      #     conn.get do |req|
      #       req.url "/"
      #       req.options.context = {
      #         formatter: OpenCensus::Trace::Formatters::CloudTrace.new
      #       }
      #     end
      #
      class FaradayMiddleware < Faraday::Middleware
        ## The default name for Faraday spans
        DEFAULT_SPAN_NAME = "faraday_request".freeze

        ##
        # Create a FaradayMiddleware.
        #
        # @param [#call] app Next item on the middleware stack.
        # @param [SpanContext] span_context The span context within which
        #     to create spans. Optional: If omitted, spans are created in the
        #     current thread-local span context.
        # @param [String, #call] span_name The name of the span to create.
        #     Can be a string or a callable that takes a faraday request env
        #     and returns a string. Optional: If omitted, uses
        #     `DEFAULT_SPAN_NAME`
        # @param [#call] sampler The sampler to use when creating spans.
        #     Optional: If omitted, uses the sampler in the current config.
        # @param [#serialize,#header_name] formatter The formatter to use when
        #     propagating span context. Optional: If omitted, defaults to the
        #     TraceContext formatter.
        #
        def initialize app, span_context: nil, span_name: nil, sampler: nil,
                       formatter: nil
          @app = app
          @span_context = span_context || OpenCensus::Trace
          @span_name = span_name || DEFAULT_SPAN_NAME
          @sampler = sampler
          @formatter = formatter || Formatters::DEFAULT
        end

        ##
        # Wraps an HTTP call with a span with the request/response info.
        # @private
        #
        def call request_env
          span_context = request_env[:span_context] || @span_context
          if span_context == OpenCensus::Trace && !span_context.span_context
            return @app.call request_env
          end

          span_name = request_env[:span_name] || @span_name
          span_name = span_name.call request_env if span_name.respond_to? :call

          span = span_context.start_span span_name, sampler: @sampler
          start_request span, request_env
          @app.call(request_env).on_complete do |response_env|
            finish_request span, response_env
            span_context.end_span span
          end
        end

        protected

        ##
        # @private Set span attributes from request object
        #
        def start_request span, env
          req_method = env[:method]
          span.put_attribute "/http/method", req_method if req_method
          url = env[:url]
          span.put_attribute "/http/url", url if url
          body = env[:body]
          body_size = body.bytesize if body.respond_to? :bytesize
          span.put_attribute "/rpc/request/size", body_size if body_size

          formatter = env[:formatter] || @formatter
          trace_context = formatter.serialize span.context
          headers = env[:request_headers] ||= {}
          headers[formatter.header_name] = trace_context
        end

        ##
        # @private Set span attributes from response
        #
        def finish_request span, env
          status = env[:status].to_i
          if status > 0
            span.set_status status
            span.put_attribute "/rpc/status_code", status
          end
          body = env[:body]
          body_size = body.bytesize if body.respond_to? :bytesize
          span.put_attribute "/rpc/response/size", body_size if body_size
        end
      end
    end
  end
end
