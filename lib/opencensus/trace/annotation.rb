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
    ##
    # A text annotation with a set of attributes.
    #
    class Annotation < TimeEvent
      ##
      # A user-supplied message describing the event.
      #
      # @return [OpenCensus::Trace::TruncatableString]
      #
      attr_reader :description

      ##
      # A set of attributes on the annotation.
      #
      # @return [Hash<String, (TruncatableString, Integer, Boolean)>]
      #
      attr_reader :attributes

      ##
      # The number of attributes that were discarded. Attributes can be
      # discarded because their keys are too long or because there are too
      # many attributes. If this value is 0, then no attributes were dropped.
      #
      # @return [Integer]
      #
      attr_reader :dropped_attributes_count

      ##
      # Create an Annotation object.
      #
      # @private
      #
      def initialize description, attributes: {}, dropped_attributes_count: 0,
                     time: nil
        super time: time
        @description = description
        @attributes = attributes
        @dropped_attributes_count = dropped_attributes_count
      end
    end
  end
end
