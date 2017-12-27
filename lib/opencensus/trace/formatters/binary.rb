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
      # the OpenCensus' BinaryEncoding specification. See
      # [documentation](https://github.com/census-instrumentation/opencensus-specs/blob/master/encodings/BinaryEncoding.md).
      #
      class Binary
        ## @private Internal format used to (un)pack binary data
        BINARY_FORMAT = "CCH32CH16CC".freeze

        ##
        # Deserialize a trace context header into a TraceContext object.
        #
        # @param [String] binary
        # @return [TraceContextData, nil]
        #
        def deserialize binary
          data = binary.unpack(BINARY_FORMAT)
          if data[0].zero? && data[1].zero? && data[3] == 1 && data[5] == 2
            TraceContextData.new data[2], data[4], data[6]
          else
            nil
          end
        end

        ##
        # Serialize a SpanContext object.
        #
        # @param [SpanContext] span_context
        # @return [String]
        #
        def serialize span_context
          [
            0, # version
            0, # field 0
            span_context.trace_id,
            1, # field 1
            span_context.span_id,
            2, # field 2
            span_context.trace_options
          ].pack(BINARY_FORMAT)
        end
      end
    end
  end
end
