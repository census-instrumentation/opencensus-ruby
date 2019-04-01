# frozen_string_literal: true

# Copyright 2019 OpenCensus Authors
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
  module Tags
    # # Tag
    #
    # A Tag consists of key, value and tag metadata(TagTTL)
    #
    class Tag
      # Invalid tag error.
      class InvalidTagError < StandardError; end

      # The maximum length for a tag key and tag value
      MAX_LENGTH = 255

      # A tag with no propagation is considered to have local scope and is
      # used within the process where it's created.
      NO_PROPAGATION = 0

      # A tag unlimited propagation can propagate unlimited hops.
      # It is typical used to track a request, which may be processed across
      # multiple entities.
      UNLIMITED_PROPAGATION = -1

      # @return [String]
      attr_reader :key

      # @return [String]
      attr_reader :value

      # @return [Integer] Represents number of hops a tag can propagate.
      attr_reader :ttl

      # Create a tag
      #
      # @param [String] key Tag key
      #   Maximum allowed length of the key is {MAX_LENGTH} and must contains
      #   only printable characters.
      # @param [String] value Tag value
      #   Maximum allowed length of the key is {MAX_LENGTH}. Value can be a
      #   nil value but if it present it must contains only printable
      #   characters.
      # @param [Integer] ttl Tag Represents number of hops a tag can propagate.
      #    Default value is {UNLIMITED_PROPAGATION} unlimited propagation.
      #   Currently only two special values {NO_PROPAGATION} and
      #   {UNLIMITED_PROPAGATION} are supported.
      # @raise [InvalidTagError] If invalid tag key or value.
      #   key: If key is empty, length grater then {MAX_LENGTH} characters or
      #   contains non printable characters
      #   value: If value length grater then 255 characters
      #   or contains non printable characters
      #
      def initialize key, value, ttl: nil
        validate_key! key
        validate_value! value
        @key = key
        @value = value
        @ttl = ttl || UNLIMITED_PROPAGATION
      end

      # Check tag can propagate
      # @return [Boolean]
      def propagate?
        @ttl == -1 || @ttl > 0
      end

      # Set no propagation A tag with no propagation is considered to have
      # local scope and is used within the process where it's created.
      def set_no_propagation
        @ttl = NO_PROPAGATION
      end

      # Set unlimited propagation
      # A tag unlimited propagation can propagate unlimited hops.
      # It is typical used to track a request, which may be processed across
      # multiple entities.
      def set_unlimited_propagation
        @ttl = UNLIMITED_PROPAGATION
      end

      private

      # Validate tag key.
      # @param [String] value
      # @raise [InvalidTagError] If key is empty, length grater then 255
      #   characters or contains non printable characters
      #
      def validate_key! value
        if value.empty? || value.length > MAX_LENGTH || !printable_str?(value)
          raise InvalidTagError, "Invalid tag key #{key}"
        end
      end

      # Validate tag value.
      # @param [String] value
      # @raise [InvalidTagError] If value length grater then 255 characters
      #   or contains non printable characters
      #
      def validate_value! value
        if (value && value.length > MAX_LENGTH) || !printable_str?(value)
          raise InvalidTagError, "Invalid tag value #{value}"
        end
      end

      # Check string is printable.
      # @param [String] str
      # @return [Boolean]
      #
      def printable_str? str
        str.bytes.none? { |b| b < 32 || b > 126 }
      end
    end
  end
end
