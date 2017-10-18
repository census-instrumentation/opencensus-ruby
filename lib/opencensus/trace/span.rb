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
      SPAN_KIND_UNKNOWN   = :UNKNOWN
      SPAN_KIND_CLIENT    = :CLIENT
      SPAN_KIND_SERVER    = :SERVER
      SPAN_KIND_PRODUCER  = :PRODUCER
      SPAN_KIND_CONSUMER  = :CONSUMER

      ##
      # The numeric ID of this span.
      #
      # @return [Integer]
      #
      attr_accessor :span_id

      ##
      # The ID of the parent span, as an integer that may be zero if this
      # is a true root span.
      #
      # @return [Integer]
      #
      attr_accessor :parent_span_id

      ##
      # FIXME
      attr_accessor :kind

      ##
      # The name of this span.
      #
      # @return [String]
      #
      attr_accessor :name

      ##
      # The starting timestamp of this span in UTC, or `nil` if the
      # starting timestamp has not yet been populated.
      #
      # @return [Time, nil]
      #
      attr_accessor :start_time

      ##
      # The ending timestamp of this span in UTC, or `nil` if the
      # ending timestamp has not yet been populated.
      #
      # @return [Time, nil]
      #
      attr_accessor :end_time

      ##
      # The properties of this span.
      #
      # @return [Hash{String => String}]
      #
      attr_accessor :labels

      ##
      # Create an empty Span object.
      #
      # @private
      #
      def initialize name, span_id: nil, parent_span_id: nil, kind: nil, start_time: nil, end_time: nil, labels: {}
        @span_id = span_id
        @name = name
        @parent_span_id = parent_span_id
        @kind = kind
        @start_time = start_time
        @end_time = end_time
        @labels = labels
      end

      ##
      # Standard value equality check for this object.
      #
      # @param [Object] other
      # @return [Boolean]
      #
      # rubocop:disable Metrics/AbcSize
      def eql? other
        other.is_a?(OpenCensus::Trace::Span) &&
          span_id == other.span_id &&
          parent_span_id == other.parent_span_id &&
          kind == other.kind &&
          name == other.name &&
          start_time == other.start_time &&
          end_time == other.end_time &&
          labels == other.labels
      end
      alias_method :==, :eql?

      ##
      # Sets the starting timestamp for this span to the current time.
      # Asserts that the timestamp has not yet been set, and throws a
      # RuntimeError if that is not the case.
      # Also ensures that all ancestor spans have already started, and
      # starts them if not.
      #
      def start!
        fail "Span already started" if start_time
        self.start_time = ::Time.now.utc
      end

      ##
      # Sets the ending timestamp for this span to the current time.
      # Asserts that the timestamp has not yet been set, and throws a
      # RuntimeError if that is not the case.
      # Also ensures that all descendant spans have also finished, and
      # finishes them if not.
      #
      def finish!
        fail "Span not yet started" unless start_time
        fail "Span already finished" if end_time
        self.end_time = ::Time.now.utc
      end
    end
  end
end
