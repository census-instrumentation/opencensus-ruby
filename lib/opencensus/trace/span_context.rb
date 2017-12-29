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

module OpenCensus
  module Trace
    ##
    # Span represents a span in a trace record. Spans are contained in
    # a trace and arranged in a forest. That is, each span may be a root span
    # or have a parent span, and may have zero or more children.
    #
    class SpanContext
      ##
      # Internal struct that holds trace-wide data.
      #
      # @private
      #
      TraceData = Struct.new :trace_id, :trace_options, :span_map, :rack_env,
                             :formatter
      ##
      # Maximum integer value for a `trace_id`
      #
      # @private
      #
      MAX_TRACE_ID = 0xffffffffffffffffffffffffffffffff

      ##
      # Maximum integer value for a `span_id`
      #
      # @private
      #
      MAX_SPAN_ID = 0xffffffffffffffff

      class << self
        ##
        # Create a new root SpanContext object, given either a Trace-Context
        # header value by itself, or an entire Rack environment. If a valid
        # Trace-Context header can be obtained from either source, it is used
        # to generate the SpanContext. Otherwise, a new root context with a
        # unique `trace_id` and a root `span_id` of "" is used.
        #
        # @param [String] header A Trace-Context header (optional)
        # @param [Hash] rack_env The Rack environment hash (optional)
        #
        # @return [SpanContext]
        #
        def create_root header: nil, rack_env: nil, formatter: nil
          formatter ||= Formatters::DEFAULT
          header ||= rack_env["HTTP_TRACE_CONTEXT"] if rack_env
          trace_context = formatter.deserialize header if header

          if trace_context
            trace_data = TraceData.new \
              trace_context.trace_id, trace_context.trace_options, {}, rack_env,
              formatter
            new trace_data, nil, trace_context.span_id
          else
            trace_id = rand 1..MAX_TRACE_ID
            trace_id = trace_id.to_s(16).rjust(32, "0")
            trace_data = TraceData.new trace_id, 0, {}, rack_env, formatter
            new trace_data, nil, ""
          end
        end
      end

      ##
      # The parent of this context, or `nil` if this is a root context.
      #
      # @return [SpanContext, nil]
      #
      attr_reader :parent

      ##
      # Returns true if this is a root span context
      #
      # @return [boolean]
      #
      def root?
        parent.nil?
      end

      ##
      # The root context, which may be this context or one of its ancestors.
      #
      # @return [SpanContext]
      #
      def root
        root = self
        until (parent = root.parent).nil?
          root = parent
        end
        root
      end

      ##
      # The trace ID, as a 32-character hex string.
      #
      # @return [String]
      #
      def trace_id
        @trace_data.trace_id
      end

      ##
      # The original trace options byte used to create this span context.
      #
      # @return [Integer]
      #
      def trace_options
        @trace_data.trace_options
      end

      ##
      # The span ID as a 16-character hex string, or the empty string if the
      # context refers to the root of the trace.
      #
      # @return [String]
      #
      attr_reader :span_id

      ##
      # Whether the context (e.g. the parent span) has been sampled. This
      # information may be used in sampling decisions for new spans.
      #
      # @return [boolean]
      #
      def sampled?
        span = this_span
        if span
          span.sampled
        else
          trace_options & 0x01 != 0
        end
      end

      ##
      # Generate and return a Trace-Context header value corresponding to
      # this context. This header may be passed as a Trace-Context to
      # downstream remote API calls.
      #
      # @return [String]
      #
      def to_trace_context_header
        @trace_data.formatter.serialize self
      end

      ##
      # Create a new span in this context.
      # You must pass a name for the span. All other span attributes should
      # be set using the SpanBuilder methods.
      # The span will be started automatically with the current timestamp.
      # However, you are responsible for finishing the span yourself.
      #
      # @param [String] name Name of the span
      # @param [Sampler] sampler Span-scoped sampler. If not provided,
      #     defaults to the trace configuration's default sampler.
      #
      # @return [SpanBuilder] A SpanBuilder object that you can use to
      #     set span attributes and create children.
      #
      def start_span name, skip_frames: 0, sampler: nil
        child_context = create_child
        sampler ||= OpenCensus::Trace::Config.default_sampler
        sampled = sampler.call span_context: self,
                               rack_env: @trace_data.rack_env
        span = SpanBuilder.new child_context, sampled,
                               skip_frames: skip_frames + 1
        span.name = name
        span.start!
        @trace_data.span_map[child_context.span_id] = span
      end

      ##
      # Create a new span in this context.
      # You must pass a name for the span. All other span attributes should
      # be set using the SpanBuilder methods.
      #
      # The span will be started automatically with the current timestamp. The
      # SpanBuilder will then be passed to the block you provide. The span will
      # be finished automatically at the end of the block.
      #
      # @param [String] name Name of the span
      # @param [Sampler] sampler Span-scoped sampler. If not provided,
      #     defaults to the trace configuration's default sampler.
      #
      def in_span name, skip_frames: 0, sampler: nil
        span = start_span name, skip_frames: skip_frames + 1, sampler: sampler
        begin
          yield span
        ensure
          end_span span
        end
      end

      ##
      # Finish the given span, which must have been created by this span
      # context.
      #
      # @param [SpanBuilder] span The span to finish.
      #
      def end_span span
        unless span.context.parent == self
          raise "The given span was not created by this context"
        end
        span.finish!
      end

      ##
      # Returns the span that defines this context; that is, the span that is
      # the parent of spans created by this context. Returns `nil` if this
      # context is the root and doesn't correspond to an actual span, or if
      # the corresponding span is remote.
      #
      # @return [SpanBuilder, nil] The span defining this context.
      #
      def this_span
        get_span span_id
      end

      ##
      # Builds all finished spans under this context, and returns an array of
      # built `Span` objects. Ignores any unfinished spans. The order of the
      # generated spans is undefined.
      #
      # Does not build any ancestor spans. If you want the entire span tree
      # built, call this method on the `#root` context.
      #
      # @return [Array<Span>] Built Span objects
      #
      def build_contained_spans
        contained_span_builders.find_all(&:finished?).map(&:to_span)
      end

      ##
      # Initialize a SpanContext object. This low-level constructor is used
      # internally only. Generally, you should create a SpanContext using the
      # `SpanContext.create_root` method.
      #
      # @private
      #
      def initialize trace_data, parent, span_id
        @trace_data = trace_data
        @parent = parent
        @span_id = span_id
      end

      ##
      # Returns true if this context equals or is an ancestor of the given
      # context.
      #
      # @private
      # @return [boolean]
      #
      def contains? context
        until context.nil?
          return true if context == self
          context = context.parent
        end
        false
      end

      ##
      # Returns all SpanBuilder objects created by this context or any
      # descendant context. The order of the returned spans is undefined.
      #
      # @private
      # @return [Array<SpanBuilder>]
      #
      def contained_span_builders
        builders = @trace_data.span_map.values
        if root?
          builders
        else
          builders.find_all { |sb| contains? sb.context.parent }
        end
      end

      private

      ##
      # Create a child of this SpanContext, with a random unique span ID.
      #
      # @return [SpanContext] The created child context.
      #
      def create_child
        loop do
          child_span_id = rand 1..MAX_SPAN_ID
          child_span_id = child_span_id.to_s(16).rjust(16, "0")
          unless @trace_data.span_map.key? child_span_id
            return SpanContext.new @trace_data, self, child_span_id
          end
        end
      end

      ##
      # Get the SpanBuilder given a Span ID.
      #
      # @param [Integer] span_id the ID of the span to get
      # @return [SpanBuilder, nil] The SpanBuilder, or `nil` if ID not found
      #
      def get_span span_id
        @trace_data.span_map[span_id]
      end
    end
  end
end
