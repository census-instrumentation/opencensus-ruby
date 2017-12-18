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
      # A collection of links, which are references from this span to a span in
      # the same or different trace.
      class Links
        ##
        # A collection of links.
        #
        # @return [TimeEvent[]]
        #
        attr_reader :links

        ##
        # The number of dropped links after the maximum size was enforced
        # If the value is 0, then no links were dropped.
        #
        # @return [Fixnum]
        #
        attr_reader :dropped_links_count

        ##
        # Create an empty Links object
        #
        # @private
        #
        def initialize links: [], dropped_links_count: 0
          @links = links
          @dropped_links_count = dropped_links_count
        end
      end
    end
  end
end
