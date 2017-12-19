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

require "opencensus/trace/config"
require "opencensus/trace/exporters"
require "opencensus/trace/integrations"
require "opencensus/trace/samplers"
require "opencensus/trace/span_builder"
require "opencensus/trace/span_context"

module OpenCensus
  module Trace
    SPAN_CONTEXT_KEY = :__span_context__

    class << self
      def set_span_context span_context
        OpenCensus::Context.set SPAN_CONTEXT_KEY, span_context
      end

      def unset_span_context
        OpenCensus::Context.unset SPAN_CONTEXT_KEY
      end

      def current_span_context
        OpenCensus::Context.get SPAN_CONTEXT_KEY
      end

      def current_span
        context = current_span_context
        context ? context.this_span : nil
      end

      def start_request_trace rack_env: nil
        span_context = SpanContext.create_from_rack_env rack_env
        set_span_context span_context
        if block_given?
          begin
            yield span_context
          ensure
            unset_span_context
          end
        end
      end

      def start_span name
        current_span_context.start_span name
      end

      def in_span name, &block
        current_span_context.in_span name, &block
      end

      def end_span
        context = current_span_context
        raise "No currently active span context" unless context
        span = context.this_span
        raise "No currently active span" unless span
        span.finish!
        set_span_context context.parent
        span
      end
    end
  end
end
