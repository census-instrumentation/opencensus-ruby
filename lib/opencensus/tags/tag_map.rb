# frozen_string_literal: true


require "forwardable"

module OpenCensus
  module Tags
    class TagMap
      extend Forwardable

      # The maximum length for a tag key and tag value
      MAX_LENGTH = 255

      def initialize tags = {}
        @tags = {}

        tags.each do |key, value|
          self[key] = value
        end
      end

      def []= key, value
        validate_key! key
        validate_value! value

        @tags[key] = value
      end

      def to_binary
        Formatters::Binary.new.serialize self
      end

      def self.from_binary data
        Formatters::Binary.new.deserialize data
      end

      def_delegators :@tags, :[], :each, :delete, :delete_if, :length, :to_h

      private

      # @private
      class InvaliedTagError < StandardError; end

      def validate_key! key
        if key.empty? || key.length > MAX_LENGTH || !printable_str?(key)
          raise InvaliedTagError, "Invalid tag key #{key}"
        end
      end

      def validate_value! value
        if (value && value.length > MAX_LENGTH) || !printable_str?(value)
          raise InvaliedTagError, "Invalid tag value #{value}"
        end
      end

      def printable_str? str
        str.bytes.none? { |b| b < 32 || b > 126 }
      end
    end
  end
end
