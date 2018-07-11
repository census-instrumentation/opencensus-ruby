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

require "opencensus/trace/annotation"
require "opencensus/trace/config"
require "opencensus/trace/exporters"
require "opencensus/trace/formatters"
require "opencensus/trace/integrations"
require "opencensus/trace/link"
require "opencensus/trace/message_event"
require "opencensus/trace/samplers"
require "opencensus/trace/span_builder"
require "opencensus/trace/span_context"
require "opencensus/trace/span"
require "opencensus/trace/status"
require "opencensus/trace/trace_context_data"
require "opencensus/trace/truncatable_string"

module OpenCensus
  ##
  # # OpenCensus Trace API
  #
  # This is a Ruby implementation of OpenCensus Trace, providing a common API
  # for latency trace tools.
  #
  module Trace
    ##
    # Internal key for storing the current SpanContext in the thread local
    # Context
    #
    # @private
    #
    SPAN_CONTEXT_KEY = :__span_context__

    class << self
      ##
      # Sets the current thread-local SpanContext, which governs the behavior
      # of the span creation class methods of OpenCensus::Trace.
      #
      # @param [SpanContext] span_context
      #
      def span_context= span_context
        OpenCensus::Context.set SPAN_CONTEXT_KEY, span_context
      end

      ##
      # Unsets the current thread-local SpanContext, disabling span creation
      # class methods of OpenCensus::Trace
      #
      def unset_span_context
        OpenCensus::Context.unset SPAN_CONTEXT_KEY
      end

      ##
      # Returns the current thread-local SpanContext, which governs the
      # behavior of the span creation class methods of OpenCensus::Trace.
      # Returns `nil` if there is no current SpanContext.
      #
      # @return [SpanContext, nil]
      #
      def span_context
        OpenCensus::Context.get SPAN_CONTEXT_KEY
      end

      ##
      # Starts tracing a request in the current thread, by creating a new
      # SpanContext and setting it as the current thread-local context.
      # Generally you should call this when beginning the handling of a
      # request. If there is a rack environment or a provided Trace-Parent
      # header, pass it in so the SpanContext is constructed accordingly.
      #
      # If you pass a block, this method will yield the SpanContext to the
      # block. When the block finishes, the span context will automatically
      # be unset. If you do not pass a block, this method will return the
      # SpanContext. You must then call `unset_span_context` yourself at the
      # end of the request
      #
      # @param [TraceContextData] trace_context The request's incoming trace
      #      context (optional)
      # @param [boolean, nil] same_process_as_parent Set to `true` if the parent
      #      span is local, `false` if it is remote, or `nil` if there is no
      #      parent span or this information is not available.
      #
      def start_request_trace trace_context: nil, same_process_as_parent: nil
        span_context = SpanContext.create_root \
          trace_context: trace_context,
          same_process_as_parent: same_process_as_parent
        self.span_context = span_context
        if block_given?
          begin
            yield span_context
          ensure
            unset_span_context
          end
        end
      end

      ##
      # Create a new span in the current thread-local context.
      # You must pass a name for the span. All other span attributes should
      # be set using the SpanBuilder methods.
      #
      # The span will be started automatically with the current timestamp.
      # However, you are responsible for finishing the span yourself.
      # Furthermore, the current thread-local SpanContext will be updated so
      # subsequent calls to `start_span` will create spans within the new span.
      #
      # You should always match `start_span` calls with a corresponding call to
      # `end_span`, which finishes the span and updates the SpanContext
      # accordingly. If you want this done automatically, consider using
      # the `in_span` method.
      #
      # Will throw an exception if there is no current SpanContext.
      #
      # @param [String] name Name of the span
      # @param [Symbol] kind Kind of span. Defaults to unspecified.
      # @param [Sampler] sampler Span-scoped sampler. If not provided,
      #     defaults to the trace configuration's default sampler.
      #
      # @return [SpanBuilder] A SpanBuilder object that you can use to
      #     set span attributes and create children.
      #
      def start_span name, kind: nil, skip_frames: 0, sampler: nil
        context = span_context
        raise "No currently active span context" unless context
        span = context.start_span name, kind: kind,
                                        skip_frames: skip_frames + 1,
                                        sampler: sampler
        self.span_context = span.context
        span
      end

      ##
      # Create a new span in this context.
      # You must pass a name for the span. All other span attributes should
      # be set using the SpanBuilder methods.
      #
      # The span will be started automatically with the current timestamp. The
      # SpanBuilder will then be passed to the block you provide. The span will
      # be finished automatically at the end of the block. Within the block,
      # the thread-local SpanContext will be updated so calls to `start_span`
      # will create subspans.
      #
      # @param [String] name Name of the span
      # @param [Symbol] kind Kind of span. Defaults to unspecified.
      # @param [Sampler] sampler Span-scoped sampler. If not provided,
      #     defaults to the trace configuration's default sampler.
      #
      def in_span name, kind: nil, skip_frames: 0, sampler: nil
        span = start_span name, kind: kind, skip_frames: skip_frames + 1,
                                sampler: sampler
        begin
          yield span
        ensure
          end_span span
        end
      end

      ##
      # Finish the given span, which must be the span that created the
      # current thread-local SpanContext. Also updates the thread-local
      # SpanContext so subsequent calls no longer create subspans of the
      # finished span.
      #
      # @param [SpanBuilder] span The expected currently active span to finish.
      #
      def end_span span
        context = span_context
        raise "No currently active span context" unless context
        unless span.equal? context.this_span
          raise "The given span doesn't match the currently active span"
        end
        span.finish!
        self.span_context = context.parent
        span
      end
    end
  end
end
