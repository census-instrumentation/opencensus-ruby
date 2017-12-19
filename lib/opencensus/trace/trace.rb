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
    class Trace
      attr_accessor :trace_id
      attr_accessor :spans
      attr_accessor :stack

      def initialize trace_id: nil, spans: [], stack: [], span_id_generator: nil
        @trace_id = trace_id || unique_trace_id
        @spans = spans
        @stack = stack

        @span_id_generator =
          span_id_generator || ::Proc.new { rand(0xffffffffffffffff) + 1 }
        @spans_by_id = {}
      end

      def in_span name, labels: {}
        span = OpenCensus::Trace::SpanBuilder.new name, span_id: unique_span_id, labels: labels
        span.parent_span_id = spans.last.span_id unless spans.empty?
        span.start!
        spans.push(span)
        stack.push(span)
        yield span
      ensure
        stack.pop
        span.finish!
      end

      private

      ##
      # Generates and returns a span ID that is unique in this trace.
      #
      # @private
      #
      def unique_span_id
        loop do
          id = @span_id_generator.call
          return id if !@spans_by_id.include?(id)
        end
      end

      ##
      # Returns a random trace ID (as a random type 4 UUID).
      #
      # @private
      # @return [String]
      #
      def unique_trace_id
        val = rand 0x100000000000000000000000000000000
        val &= 0xffffffffffff0fffcfffffffffffffff
        val |= 0x00000000000040008000000000000000
        format("%032x", val)
      end
    end
  end
end
