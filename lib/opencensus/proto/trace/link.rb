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
      # A pointer from the current span to another span in the same trace or in
      # a different trace. For example, this can be used in batching operations,
      # where a single batch handler processes multiple requests from different
      # traces or when the handler receives a request from a different project.
      #
      class Link
        # The relationship of the two spans is unknown, or known but other
        # than parent-child.
        LINK_TYPE_UNSPECIFIED         = :TYPE_UNSPECIFIED

        # The linked span is a child of the current span.
        LINK_TYPE_CHILD_LINKED_SPAN   = :CHILD_LINKED_SPAN

        # The linked span is a parent of the current span.
        LINK_TYPE_PARENT_LINKED_SPAN  = :PARENT_LINKED_SPAN

        ##
        # A unique identifier for a trace. All spans from the same trace share
        # the same `trace_id`. The ID is a 16-byte array.
        #
        # @return [String]
        #
        attr_reader :trace_id

        ##
        # A unique identifier for a span within a trace, assigned when the span
        # is created. The ID is an 8-byte array.
        #
        # @return [String]
        #
        attr_reader :span_id

        ##
        # The relationship of the current span relative to the linked span.
        #
        # @return [Symbol]
        attr_reader :type

        ##
        # A set of attributes on the link.
        #
        # @return [Hash{String => String}]
        attr_reader :attributes

        ##
        # The number of attributes that were discarded. Attributes can be
        # discarded because their keys are too long or because there are too
        # many attributes. If this value is 0, then no attributes were dropped.
        attr_reader :dropped_attributes_count

        ##
        # Create a Link object.
        #
        # @private
        #
        def initialize trace_id, span_id, type: nil, attributes: {}
          @trace_id = trace_id
          @span_id = span_id
          @type = type
          @attributes = attributes
        end
      end
    end
  end
end
