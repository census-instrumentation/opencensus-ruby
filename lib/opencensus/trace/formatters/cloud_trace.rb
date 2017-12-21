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
      ##
      # This formatter serializes and deserializes span context according to
      # the Google X-Cloud-Trace header specification.
      #
      class CloudTrace
        HEADER_FORMAT = /([0-9a-fA-F]{32})(?:\/(\d+))?(?:;o=(\d+))?/

        ##
        # Deserialize a trace context header into a TraceContext object.
        #
        # @param [String]
        # @return [TraceContext, nil]
        #
        def deserialize header
          if match = HEADER_FORMAT.match(header)
            trace_id = match[1]
            span_id = sprintf("%016x", match[2].to_i)
            trace_options = match[3].to_i
            TraceContextData.new trace_id, span_id, trace_options
          else
            nil
          end
        end

        ##
        # Serialize a SpanContext object.
        #
        # @param [SpanContext]
        # @return [String]
        #
        def serialize span_context
          ret = span_context.trace_id
          ret << '/' << span_context.span_id.to_i(16).to_s if span_context.span_id
          ret << ';o=' << span_context.trace_options.to_s if span_context.trace_options
          ret
        end
      end
    end
  end
end
