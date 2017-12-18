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
  module Proto
    module Trace
      ##
      # A text annotation with a set of attributes.
      #
      class Attributes
        ##
        # The set of attributes. The value can be a string, an integer, or the
        # Boolean values `true` and `false`. For example:
        #
        #     "/instance_id": "my-instance"
        #     "/http/user_agent": ""
        #     "/http/server_latency": 300
        #     "abc.com/myattribute": true
        attr_reader :attribute_map

        ##
        # The number of attributes that were discarded. Attributes can be
        # discarded because their keys are too long or because there are too
        # many attributes. If this value is 0, then no attributes were dropped.
        attr_reader :dropped_attributes_count

        ##
        # Create an empty Attributes object.
        #
        # @private
        #
        def initialize attribute_map: {}, dropped_attributes_count: 0
          @attribute_map = attribute_map
          @dropped_attributes_count = dropped_attributes_count
        end
      end
    end
  end
end
