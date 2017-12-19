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
    module Formatters
      class CloudTrace
        CONTEXT_HEADER_FORMAT = /([0-9a-fA-F]{32})(?:\/(\d+))?(?:;o=(\d+))?/

        def deserialize header
          if match = CONTEXT_HEADER_FORMAT.match header
            trace_id = match[1]
            span_id = match[2]
            trace_options = match[3].to_i
            SpanContext.new trace_id, span_id, trace_options
          else
            SpanContext.new
          end
        end

        def serialize span_context
          ret = span_context.trace_id
          ret += '/' . span_context.span_id.to_i(16) if span_context.span_id
          ret += ';o=' . span_context.span_options if span_context.span_options
          ret
        end
      end
    end
  end
end
