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
        ##
        # Internal regex used to parse fields
        #
        # @private
        #
        HEADER_FORMAT = %r{([0-9a-fA-F]{32})(?:\/(\d+))?(?:;o=(\d+))?}

        ##
        # The outgoing header used for the Google Cloud Trace header
        # specification.
        #
        # @private
        #
        HEADER_NAME = "X-Cloud-Trace".freeze

        ##
        # The rack environment header used the the Google Cloud Trace header
        # specification.
        #
        # @private
        #
        RACK_HEADER_NAME = "HTTP_X_CLOUD_TRACE".freeze

        ##
        # Returns the name of the header used for context propagation.
        #
        # @return [String]
        #
        def header_name
          HEADER_NAME
        end

        ##
        # Returns the name of the rack_environment header to use when parsing
        # context from an incoming request.
        #
        # @return [String]
        #
        def rack_header_name
          RACK_HEADER_NAME
        end

        ##
        # Deserialize a trace context header into a TraceContext object.
        #
        # @param [String] header
        # @return [TraceContextData, nil]
        #
        def deserialize header
          match = HEADER_FORMAT.match(header)
          if match
            trace_id = match[1].downcase
            span_id = format("%016x", match[2].to_i)
            trace_options = match[3].to_i
            TraceContextData.new trace_id, span_id, trace_options
          else
            nil
          end
        end

        ##
        # Serialize a TraceContextData object.
        #
        # @param [TraceContextData] trace_context
        # @return [String]
        #
        def serialize trace_context
          trace_context.trace_id.dup.tap do |ret|
            if trace_context.span_id
              ret << "/" << trace_context.span_id.to_i(16).to_s
            end
            if trace_context.trace_options
              ret << ";o=" << trace_context.trace_options.to_s
            end
          end
        end
      end
    end
  end
end
