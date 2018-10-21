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
require "uri"
require "opencensus"

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
      # formatter in the current config.
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
      class FaradayMiddleware < ::Faraday::Middleware
        ##
        # Fallback span name
        # @return [String]
        #
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
        #     and returns a string. Optional: If omitted, uses the request path
        #     as recommended in the OpenCensus spec.
        # @param [#call] sampler The sampler to use when creating spans.
        #     Optional: If omitted, uses the sampler in the current config.
        # @param [#serialize,#header_name] formatter The formatter to use when
        #     propagating span context. Optional: If omitted, use the formatter
        #     in the current config.
        #
        def initialize app, span_context: nil, span_name: nil, sampler: nil,
                       formatter: nil
          @app = app
          @span_context = span_context || OpenCensus::Trace
          @default_span_name = span_name
          @sampler = sampler
          @formatter = formatter || OpenCensus::Trace.config.http_formatter
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

          span_name = extract_span_name(request_env) || @default_span_name ||
                      DEFAULT_SPAN_NAME
          span_name = span_name.call request_env if span_name.respond_to? :call

          span = span_context.start_span span_name, sampler: @sampler
          start_request span, request_env
          begin
            @app.call(request_env).on_complete do |response_env|
              finish_request span, response_env
            end
          rescue StandardError => e
            span.set_status 2, e.message
            raise
          ensure
            span_context.end_span span
          end
        end

        protected

        ##
        # @private Get the span name from the request object
        #
        def extract_span_name env
          name = env[:span_name]
          return name if name
          uri = build_uri env
          return nil unless uri
          path = uri.path.to_s
          path.start_with?("/") ? path : "/#{path}"
        end

        ##
        # @private Set span attributes from request object
        #
        def start_request span, env
          span.kind = SpanBuilder::CLIENT
          req_method = env[:method]
          span.put_attribute "http.method", req_method.upcase if req_method
          uri = build_uri env
          if uri
            span.put_attribute "http.host", uri.hostname.to_s
            span.put_attribute "http.path", uri.path.to_s
          end
          body = env[:body]
          body_size = body.respond_to?(:bytesize) ? body.bytesize : 0
          span.put_message_event SpanBuilder::SENT, 1, body_size

          formatter = env[:formatter] || @formatter
          if formatter.respond_to? :header_name
            headers = env[:request_headers] ||= {}
            trace_context = formatter.serialize span.context.trace_context
            headers[formatter.header_name] = trace_context
          end
        end

        ##
        # @private Set span attributes from response
        #
        def finish_request span, env
          status = env[:status].to_i
          if status > 0
            span.set_http_status status
            span.put_attribute "http.status_code", status
          end
          body = env[:body]
          body_size = body.respond_to?(:bytesize) ? body.bytesize : 0
          span.put_message_event SpanBuilder::RECEIVED, 1, body_size
        end

        private

        def build_uri env
          ::URI.parse env[:url]
        rescue ::URI::InvalidURIError
          nil
        end
      end
    end
  end
end
