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


require "opencensus/tags/tag_map"

module OpenCensus
  ##
  # The Tags module contains support for OpenCensus tags. Tags are key-value
  # pairs. Tags provide additional cardinality to the OpenCensus instrumentation
  # data.
  #
  module Tags
    TAGS_CONTEXT_KEY = :__tags_context__

    class << self
      def tags_context= context
        OpenCensus::Context.set TAGS_CONTEXT_KEY, context
      end

      def unset_tags_context
        OpenCensus::Context.unset TAGS_CONTEXT_KEY
      end

      def tags_context
        OpenCensus::Context.get TAGS_CONTEXT_KEY
      end
    end
  end
end
