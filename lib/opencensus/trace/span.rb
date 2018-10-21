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
    class Span
      ##
      # A span kind, indicating the span kind is unspecified.
      # @return [Symbol]
      #
      SPAN_KIND_UNSPECIFIED = :SPAN_KIND_UNSPECIFIED

      ##
      # A span kind, indicating that the span covers server-side handling of an
      # RPC or other remote network request.
      # @return [Symbol]
      #
      SERVER = :SERVER

      ##
      # A span kind, indicating that the span covers the client-side wrapper
      # around an RPC or other remote request.
      # @return [Symbol]
      #
      CLIENT = :CLIENT

      ##
      # A unique identifier for a trace. All spans from the same trace share
      # the same `trace_id`. The ID is a 16-byte value represented as a
      # hexadecimal string.
      #
      # @return [String]
      #
      attr_reader :trace_id

      ##
      # A unique identifier for a span within a trace, assigned when the span
      # is created. The ID is an 8-byte value represented as a hexadecimal
      # string.
      #
      # @return [String]
      #
      attr_reader :span_id

      ##
      # The `span_id` of this span's parent span. If this is a root span, then
      # this field must be empty. The ID is an 8-byte value represented as a
      # hexadecimal string.
      #
      # @return [String]
      #
      attr_reader :parent_span_id

      ##
      # The name of this span.
      #
      # @return [TruncatableString]
      #
      attr_reader :name

      ##
      # The kind of span. Can be used to specify additional relationships
      # between spans in addition to a parent/child relationship.
      # You should use the kind constants provided by this class.
      #
      # @return [Symbol]
      #
      attr_reader :kind

      ##
      # The starting timestamp of this span in UTC.
      #
      # @return [Time]
      #
      attr_reader :start_time

      ##
      # The ending timestamp of this span in UTC.
      #
      # @return [Time]
      #
      attr_reader :end_time

      ##
      # The properties of this span.
      #
      # @return [Hash<String, (TruncatableString, Integer, Boolean)>]
      #
      attr_reader :attributes

      ##
      # The number of attributes that were discarded. Attributes can be
      # discarded because their keys are too long or because there are too
      # many attributes. If this value is 0, then no attributes were dropped.
      #
      # @return [Integer]
      #
      attr_reader :dropped_attributes_count

      ##
      # A stack trace captured at the start of the span.
      #
      # @return [Array<Thread::Backtrace::Location>]
      #
      attr_reader :stack_trace

      ##
      # A hash of the stack trace. This may be used by exporters to identify
      # duplicate stack traces transmitted in the same request; only one copy
      # of the actual data needs to be sent.
      #
      # @return [Integer]
      #
      attr_reader :stack_trace_hash_id

      ##
      # The number of stack frames that were dropped because there were too many
      # stack frames. If this value is 0, then no stack frames were dropped.
      #
      # @return [Integer]
      #
      attr_reader :dropped_frames_count

      ##
      # The included time events.
      #
      # @return [Array<TimeEvent>]
      #
      attr_reader :time_events

      ##
      # The number of dropped annotations in all the included time events.
      # If the value is 0, then no annotations were dropped.
      #
      # @return [Integer]
      #
      attr_reader :dropped_annotations_count

      ##
      # The number of dropped message events in all the included time events.
      # If the value is 0, then no message events were dropped.
      #
      # @return [Integer]
      #
      attr_reader :dropped_message_events_count

      ##
      # The included links.
      #
      # @return [Array<Link>]
      #
      attr_reader :links

      ##
      # The number of dropped links after the maximum size was enforced
      # If the value is 0, then no links were dropped.
      #
      # @return [Integer]
      #
      attr_reader :dropped_links_count

      ##
      # An optional final status for this span.
      #
      # @return [Status, nil]
      #
      attr_reader :status

      ##
      # A highly recommended but not required flag that identifies when a trace
      # crosses a process boundary. True when the parent_span belongs to the
      # same process as the current span.
      #
      # @return [boolean, nil]
      #
      attr_reader :same_process_as_parent_span

      ##
      # An optional number of child spans that were generated while this span
      # was active. If set, allows an implementation to detect missing child
      # spans.
      #
      # @return [Integer, nil]
      #
      attr_reader :child_span_count

      ##
      # Create an empty Span object.
      #
      # @private
      #
      def initialize trace_id, span_id, name, start_time, end_time,
                     kind: SPAN_KIND_UNSPECIFIED,
                     parent_span_id: "", attributes: {},
                     dropped_attributes_count: 0, stack_trace: [],
                     dropped_frames_count: 0, time_events: [],
                     dropped_annotations_count: 0,
                     dropped_message_events_count: 0, links: [],
                     dropped_links_count: 0, status: nil,
                     same_process_as_parent_span: nil,
                     child_span_count: nil
        @name = name
        @kind = kind
        @trace_id = trace_id
        @span_id = span_id
        @parent_span_id = parent_span_id
        @start_time = start_time
        @end_time = end_time
        @attributes = attributes
        @dropped_attributes_count = dropped_attributes_count
        @stack_trace = stack_trace
        @dropped_frames_count = dropped_frames_count
        @stack_trace_hash_id = init_stack_trace_hash_id
        @time_events = time_events
        @dropped_annotations_count = dropped_annotations_count
        @dropped_message_events_count = dropped_message_events_count
        @links = links
        @dropped_links_count = dropped_links_count
        @status = status
        @same_process_as_parent_span = same_process_as_parent_span
        @child_span_count = child_span_count
      end

      private

      def init_stack_trace_hash_id
        hash_id = [@stack_trace, @dropped_frames_count].hash
        hash_id.zero? ? -1 : hash_id
      end
    end
  end
end
