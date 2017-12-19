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
require "opencensus/trace/span"
require "opencensus/trace/span_builder"
require "opencensus/trace/trace"

module OpenCensus
  module Trace
    CONTEXT_KEY = :__opencensus_trace__

    class << self
      def start
        set OpenCensus::Trace::Trace.new
      end

      def in_span name, labels: {}
        if parent = get
          parent.in_span name, labels: labels do |span|
            yield span
          end
        else
          yield nil
        end
      end

      def spans
        if parent = get
          parent.spans
        else
          []
        end
      end

      def set span
        OpenCensus::Context.set CONTEXT_KEY, span
      end

      def get
        OpenCensus::Context.get CONTEXT_KEY
      end
    end
  end
end
