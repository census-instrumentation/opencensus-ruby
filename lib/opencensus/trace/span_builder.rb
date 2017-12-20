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
    # Span represents a single span within a request trace.
    #
    class SpanBuilder
      ##
      # The context that can build children of this span.
      #
      # @return [SpanContext]
      #
      attr_reader :context

      ##
      # The trace ID, as a 32-character hex string.
      #
      # @return [String]
      #
      def trace_id
        context.trace_id
      end

      ##
      # The span ID, as a 16-character hex string.
      #
      # @return [String]
      #
      def span_id
        context.span_id
      end

      ##
      # The span ID of the parent, as a 16-character hex string, or the empty
      # string if this is a root span.
      #
      # @return [String]
      #
      def parent_span_id
        context.parent.span_id
      end

      ##
      # Sampler for this span. This field is required.
      #
      # @return [Sampler]
      #
      attr_accessor :sampler

      ##
      # A description of the span's operation.
      #
      # For example, the name can be a qualified method name or a file name and
      # a line number where the operation is called. A best practice is to use
      # the same display name at the same call point in an application.
      # This makes it easier to correlate spans in different traces.
      #
      # This field is required.
      #
      # @return [String, TruncatableString]
      #
      attr_accessor :name

      ##
      # The start time of the span. On the client side, this is the time kept
      # by the local machine where the span execution starts. On the server
      # side, this is the time when the server's application handler starts
      # running.
      #
      # In Ruby, this is represented by a Time object in UTC, or `nil` if the
      # starting timestamp has not yet been populated.
      #
      # @return [Time, nil]
      #
      attr_accessor :start_time

      ##
      # The end time of the span. On the client side, this is the time kept by
      # the local machine where the span execution ends. On the server side,
      # this is the time when the server application handler stops running.
      #
      # In Ruby, this is represented by a Time object in UTC, or `nil` if the
      # starting timestamp has not yet been populated.
      #
      # @return [Time, nil]
      #
      attr_accessor :end_time

      def start!
        raise "Span already started" unless start_time.nil?
        @start_time = Time.now.utc
        self
      end

      def finish!
        raise "Span not yet started" if start_time.nil?
        raise "Span already finished" unless end_time.nil?
        @end_time = Time.now.utc
        self
      end

      ##
      # Initializer.
      #
      # @private
      #
      def initialize span_context
        @context = span_context
        @sampler = OpenCensus::Trace::Samplers::DEFAULT
        @name = ""
        @start_time = nil
        @end_time = nil
      end
    end
  end
end
