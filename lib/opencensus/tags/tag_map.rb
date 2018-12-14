# frozen_string_literal: true


require "forwardable"

module OpenCensus
  module Tags
    # # TagMap
    #
    # Collection of tag key and value.
    # @example
    #
    #  tag_map = OpenCensus::Tags::OpenCensus.new
    #
    #  # Add or update
    #  tag_map["key1"] = "value1"
    #  tag_map["key2"] = "value2"
    #
    #  # Get value
    #  tag_map["key1"] # value1
    #
    #  # Delete
    #  tag_map.delete "key1"
    #
    #  # Iterate
    #  tag_map.each do |key, value|
    #    p key
    #    p value
    #  end
    #
    #  # Length
    #  tag_map.length # 1
    #
    # @example Create tag map from hash
    #
    #   tag_map = OpenCensus::Tags::OpenCensus.new({ "key1" => "value1"})
    #
    class TagMap
      extend Forwardable

      # The maximum length for a tag key and tag value
      MAX_LENGTH = 255

      # Create a tag map. It is a map of tags from key to value.
      # @param [Hash{String=>String}] tags Tags hash with string key and value.
      #
      def initialize tags = {}
        @tags = {}

        tags.each do |key, value|
          self[key] = value
        end
      end

      # Set tag key value
      #
      # @param [String] key Tag key
      # @param [String] value Tag value
      # @raise [InvaliedTagError] If invalid tag key or value.
      #
      def []= key, value
        validate_key! key
        validate_value! value

        @tags[key] = value
      end

      # Convert tag map to binary string format.
      # @see [documentation](https://github.com/census-instrumentation/opencensus-specs/blob/master/encodings/BinaryEncoding.md#tag-context)
      # @return [String] Binary string
      #
      def to_binary
        Formatters::Binary.new.serialize self
      end

      # Create a tag map from the binary string.
      # @param [String] data Binary string data
      # @return [TagMap]
      #
      def self.from_binary data
        Formatters::Binary.new.deserialize data
      end

      # @!method []
      #   @see Hash#[]
      # @!method each
      #   @see Hash#each
      # @!method delete
      #   @see Hash#delete
      # @!method delete_if
      #   @see Hash#delete_if
      # @!method length
      #   @see Hash#length
      # @!method to_h
      #   @see Hash#to_h
      def_delegators :@tags, :[], :each, :delete, :delete_if, :length, :to_h

      private

      # @private
      class InvaliedTagError < StandardError; end

      # @private
      #
      # Validate tag key.
      # @param [String] key
      # @raise [InvaliedTagError] If key is empty, length grater then 255
      #   characters or contains non printable characters
      #
      def validate_key! key
        if key.empty? || key.length > MAX_LENGTH || !printable_str?(key)
          raise InvaliedTagError, "Invalid tag key #{key}"
        end
      end

      # @private
      #
      # Validate tag value.
      # @param [String] value
      # @raise [InvaliedTagError] If value length grater then 255 characters
      #   or contains non printable characters
      #
      def validate_value! value
        if (value && value.length > MAX_LENGTH) || !printable_str?(value)
          raise InvaliedTagError, "Invalid tag value #{value}"
        end
      end

      # @private
      #
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
