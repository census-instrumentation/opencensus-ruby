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
      # The GoogleCloud exporter exports captured spans to Stackdriver Trace.
      # See {https://cloud.google.com/trace/ Stackdriver Trace documentation}.
      #
      class GoogleCloud
        ##
        # Export the captured spans to Stackdriver Trace.
        #
        # @param [Array<Span>] _spans The captured spans.
        # @return [Boolean]
        #
        def export _spans
          # TODO: implement GoogleCloud exporter
          false
        end
      end
    end
  end
end
