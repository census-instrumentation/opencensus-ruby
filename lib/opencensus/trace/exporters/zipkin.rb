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
    module Exporters
      ##
      # The Zipkin exporter exports captured spans to Zipkin instance.
      # See {https://github.com/openzipkin/zipkin-api Zipkin API specification}.
      #
      class Zipkin
        ##
        # Export the captured spans to the configured Zipkin instance.
        #
        # @param [Array<Span>] spans The captured spans.
        # @return [Boolean]
        #
        def export spans
          # TODO: implement Zipkin exporter
          false
        end
      end
    end
  end
end
