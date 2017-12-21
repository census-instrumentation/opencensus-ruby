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
      # the TraceContext specification. See
      # [documentation](https://github.com/TraceContext/tracecontext-spec/blob/master/trace_context/HTTP_HEADER_FORMAT.md).
      #
      class TraceContext
        VERSION_PATTERN = /^([0-9a-fA-F]{2})-(.+)$/
        HEADER_V0_PATTERN =
          /^([0-9a-fA-F]{32})-([0-9a-fA-F]{16})(-([0-9a-fA-F]{2}))?$/

        ##
        # Deserialize a trace context header into a TraceContext object.
        #
        # @param [String]
        # @return [TraceContext, nil]
        #
        def deserialize header
          match = VERSION_PATTERN.match(header)
          if match
            version = match[1].to_i(16)
            version_format = match[2]
            case version
            when 0
              parse_trace_context_header_version_0 version_format
            else
              nil
            end
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
          sprintf(
            "%02d-%s-%s-%02d",
            0, # version 0
            span_context.trace_id,
            span_context.span_id,
            span_context.trace_options
          )
        end

        private

        def parse_trace_context_header_version_0 str
          match = HEADER_V0_PATTERN.match(str)
          if match
            TraceContextData.new match[1].downcase,
                                 match[2].downcase,
                                 match[4].to_i(16)
          end
        end
      end
    end
  end
end
