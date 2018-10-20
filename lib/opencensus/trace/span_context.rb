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
    # SpanContext represents the context within which a span may be created.
    # It includes the ID of the parent trace, the ID of the parent span, and
    # sampling state.
    #
    class SpanContext
      ##
      # Internal struct that holds trace-wide data.
      # @private
      #
      TraceData = Struct.new :trace_id, :span_map

      ##
      # Maximum integer value for a `trace_id`
      # @private
      #
      MAX_TRACE_ID = 0xffffffffffffffffffffffffffffffff

      ##
      # Maximum integer value for a `span_id`
      # @private
      #
      MAX_SPAN_ID = 0xffffffffffffffff

      class << self
        ##
        # Create a new root SpanContext object, given either a traceparent
        # header value by itself, or an entire Rack environment. If a valid
        # traceparent header can be obtained from either source, it is used
        # to generate the SpanContext. Otherwise, a new root context with a
        # unique `trace_id` and a root `span_id` of "" is used.
        #
        # @param [TraceContextData] trace_context The request's incoming trace
        #      context (optional)
        # @param [boolean, nil] same_process_as_parent Set to `true` if the
        #      parent span is local, `false` if it is remote, or `nil` if there
        #      is no parent span or this information is not available.
        #
        # @return [SpanContext]
        #
        def create_root trace_context: nil, same_process_as_parent: nil
          if trace_context
            trace_data = TraceData.new trace_context.trace_id, {}
            new trace_data, nil, trace_context.span_id,
                trace_context.trace_options, same_process_as_parent
          else
            trace_id = rand 1..MAX_TRACE_ID
            trace_id = trace_id.to_s(16).rjust(32, "0")
            trace_data = TraceData.new trace_id, {}
            new trace_data, nil, "", 0, nil
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
      # Returns the trace context for this span.
      #
      # @return [TraceContextData]
      #
      def trace_context
        TraceContextData.new trace_id, @span_id, trace_options
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
      attr_reader :trace_options

      ##
      # The span ID as a 16-character hex string, or the empty string if the
      # context refers to the root of the trace.
      #
      # @return [String]
      #
      attr_reader :span_id

      ##
      # Whether the parent of spans created by this context is local, or `nil`
      # if this context creates root spans or this information is unknown.
      #
      # @return [boolean, nil]
      #
      attr_reader :same_process_as_parent

      ##
      # Whether this context (e.g. the parent span) has been sampled. This
      # information may be used in sampling decisions for new spans.
      #
      # @return [boolean]
      #
      def sampled?
        trace_options & 0x01 != 0
      end

      ##
      # Create a new span in this context.
      # You must pass a name for the span. All other span attributes should
      # be set using the SpanBuilder methods.
      # The span will be started automatically with the current timestamp.
      # However, you are responsible for finishing the span yourself.
      #
      # @param [String] name Name of the span. Required.
      # @param [Symbol] kind Kind of span. Optional. Defaults to unspecified.
      #     Other allowed values are {OpenCensus::Trace::SpanBuilder::SERVER}
      #     and {OpenCensus::Trace::SpanBuilder::CLIENT}.
      # @param [Sampler,Boolean,nil] sampler Span-scoped sampler. Optional.
      #     If provided, the sampler may be a sampler object as defined in the
      #     {OpenCensus::Trace::Samplers} module docs, or the values `true` or
      #     `false` as shortcuts for {OpenCensus::Trace::Samplers::AlwaysSample}
      #     or {OpenCensus::Trace::Samplers::NeverSample}, respectively. If no
      #     span-scoped sampler is provided, the local parent span's sampling
      #     decision is used. If there is no local parent span, the configured
      #     default sampler is used to make a sampling decision.
      #
      # @return [SpanBuilder] A SpanBuilder object that you can use to
      #     set span attributes and create children.
      #
      def start_span name, kind: nil, skip_frames: 0, sampler: nil
        child_context = create_child sampler
        span = SpanBuilder.new child_context, skip_frames: skip_frames + 1
        span.name = name
        span.kind = kind if kind
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
      # @param [String] name Name of the span. Required.
      # @param [Symbol] kind Kind of span. Optional. Defaults to unspecified.
      #     Other allowed values are {OpenCensus::Trace::SpanBuilder::SERVER}
      #     and {OpenCensus::Trace::SpanBuilder::CLIENT}.
      # @param [Sampler,Boolean,nil] sampler Span-scoped sampler. Optional.
      #     If provided, the sampler may be a sampler object as defined in the
      #     {OpenCensus::Trace::Samplers} module docs, or the values `true` or
      #     `false` as shortcuts for {OpenCensus::Trace::Samplers::AlwaysSample}
      #     or {OpenCensus::Trace::Samplers::NeverSample}, respectively. If no
      #     span-scoped sampler is provided, the local parent span's sampling
      #     decision is used. If there is no local parent span, the configured
      #     default sampler is used to make a sampling decision.
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
        get_span @span_id
      end

      ##
      # Builds spans under this context, and returns an array of built `Span`
      # objects. Builds only spans that are both finished and sampled, and
      # ignores others. The order of the generated spans is undefined.
      #
      # Does not build any ancestor spans. If you want the entire span tree
      # built, call this method on the `#root` context.
      #
      # @param [Integer, nil] max_attributes The maximum number of attributes
      #     to save, or `nil` to use the config value.
      # @param [Integer, nil] max_stack_frames The maximum number of stack
      #     frames to save, or `nil` to use the config value.
      # @param [Integer, nil] max_annotations The maximum number of annotations
      #     to save, or `nil` to use the config value.
      # @param [Integer, nil] max_message_events The maximum number of message
      #     events to save, or `nil` to use the config value.
      # @param [Integer, nil] max_links The maximum number of links to save,
      #     or `nil` to use the config value.
      # @param [Integer, nil] max_string_length The maximum length in bytes for
      #     truncated strings, or `nil` to use the config value.
      #
      # @return [Array<Span>] Built Span objects
      #
      def build_contained_spans max_attributes: nil,
                                max_stack_frames: nil,
                                max_annotations: nil,
                                max_message_events: nil,
                                max_links: nil,
                                max_string_length: nil
        sampled_span_builders = contained_span_builders.find_all do |sb|
          sb.finished? && sb.sampled?
        end
        sampled_span_builders.map do |sb|
          sb.to_span max_attributes: max_attributes,
                     max_stack_frames: max_stack_frames,
                     max_annotations: max_annotations,
                     max_message_events: max_message_events,
                     max_links: max_links,
                     max_string_length: max_string_length
        end
      end

      ##
      # Initialize a SpanContext object. This low-level constructor is used
      # internally only. Generally, you should create a SpanContext using the
      # `SpanContext.create_root` method.
      #
      # @private
      #
      def initialize trace_data, parent, span_id, trace_options,
                     same_process_as_parent
        @trace_data = trace_data
        @parent = parent
        @span_id = span_id
        @trace_options = trace_options
        @same_process_as_parent = same_process_as_parent
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
      # @param [Sampler,Boolean,nil] sampler Span-scoped sampler.
      # @return [SpanContext] The created child context.
      #
      def create_child sampler
        sampling_decision = make_sampling_decision sampler
        child_trace_options = sampling_decision ? 1 : 0
        loop do
          child_span_id = rand 1..MAX_SPAN_ID
          child_span_id = child_span_id.to_s(16).rjust(16, "0")
          unless @trace_data.span_map.key? child_span_id
            return SpanContext.new @trace_data, self, child_span_id,
                                   child_trace_options, true
          end
        end
      end

      ##
      # Make a sampling decision in the current context given a span sampler.
      # Implements the logic specified at:
      # https://github.com/census-instrumentation/opencensus-specs/blob/master/trace/Sampling.md
      #
      # @param [Sampler,Boolean,nil] sampler Span-scoped sampler.
      # @return [Boolean]
      #
      def make_sampling_decision sampler
        resolved_sampler =
          case sampler
          when true
            OpenCensus::Trace::Samplers::AlwaysSample.new
          when false
            OpenCensus::Trace::Samplers::NeverSample.new
          when nil
            root? ? OpenCensus::Trace.config.default_sampler : nil
          else
            sampler
          end
        if resolved_sampler
          resolved_sampler.call(span_context: self)
        else
          sampled?
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
