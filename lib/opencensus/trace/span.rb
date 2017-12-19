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
      # @return [OpenCensus::Trace::TruncatableString]
      #
      attr_reader :name

      ##
      # The starting timestamp of this span in UTC, or `nil` if the
      # starting timestamp has not yet been populated.
      #
      # @return [Time, nil]
      #
      attr_reader :start_time

      ##
      # The ending timestamp of this span in UTC, or `nil` if the
      # ending timestamp has not yet been populated.
      #
      # @return [Time, nil]
      #
      attr_reader :end_time

      ##
      # The properties of this span.
      #
      # @return [Hash{String => String}]
      #
      attr_reader :attributes

      ##
      # The number of attributes that were discarded. Attributes can be
      # discarded because their keys are too long or because there are too
      # many attributes. If this value is 0, then no attributes were dropped.
      attr_reader :dropped_attributes_count

      ##
      # A stack trace captured at the start of the span.
      #
      # @return [String[]]
      #
      attr_reader :stack_trace

      ##
      # The included time events.
      #
      # @return [TimeEvent[]]
      #
      attr_reader :time_events

      ##
      # The number of dropped annotations in all the included time events.
      # If the value is 0, then no annotations were dropped.
      #
      # @return [Fixnum]
      #
      attr_reader :dropped_annotations_count

      ##
      # The number of dropped message events in all the included time events.
      # If the value is 0, then no message events were dropped.
      #
      # @return [Fixnum]
      #
      attr_reader :dropped_message_events_count

      ##
      # The included links.
      #
      # @return [Link[]]
      #
      attr_reader :links

      ##
      # The number of dropped links after the maximum size was enforced
      # If the value is 0, then no links were dropped.
      #
      # @return [Fixnum]
      #
      attr_reader :dropped_links_count

      ##
      # An optional final status for this span.
      #
      # @return [Status, nil]
      attr_reader :status

      ##
      # A highly recommended but not required flag that identifies when a trace
      # crosses a process boundary. True when the parent_span belongs to the
      # same process as the current span.
      #
      # @return [Boolean]
      #
      attr_reader :same_process_as_parent_span

      ##
      # An optional number of child spans that were generated while this span
      # was active. If set, allows an implementation to detect missing child
      # spans.
      #
      # @return [Fixnum]
      #
      attr_reader :child_span_count

      ##
      # Create an empty Span object.
      #
      # @private
      #
      def initialize name, trace_id: nil, span_id: nil, parent_span_id: nil,
                           kind: nil, start_time: nil, end_time: nil,
                           attributes: nil, stack_trace: [], time_events: nil,
                           links: nil, status: nil,
                           same_process_as_parent_span: true,
                           child_span_count: nil
        @name = name
        @trace_id = trace_id
        @span_id = span_id
        @parent_span_id = parent_span_id
        @kind = kind
        @start_time = start_time
        @end_time = end_time
        @attributes = attributes
        @stack_trace = stack_trace
        @time_events = time_events
        @links = links
        @status = status
        @same_process_as_parent_span = same_process_as_parent_span
        @child_span_count = child_span_count
      end
    end
  end
end
