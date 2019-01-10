# frozen_string_literal: true

module OpenCensus
  module Tags
    module Formatters
      ##
      # This formatter serializes and deserializes tags context according to
      # the OpenCensus' BinaryEncoding specification. See
      # [documentation](https://github.com/census-instrumentation/opencensus-specs/blob/master/encodings/BinaryEncoding.md).
      #
      # @example Serialize
      #
      # formatter = OpenCensus::Tags::Formatters::Binary.new
      #
      # tag_map = OpenCensus::Tags::TagMap.new({\"key1" => \"val1"})
      # binary = formatter.serialize tag_map # "\x00\x00\x04key1\x04val1"
      #
      # @example Deserialize
      #
      # formatter = OpenCensus::Tags::Formatters::Binary.new
      #
      # binary = "\x00\x00\x04key1\x04val1"
      # tag_map = formatter.deserialize binary
      #
      class Binary
        # Binary formatter error.
        class BinaryFormatterError < StandardError; end

        # @private
        #
        # Seralization version
        VERSION_ID = 0

        # @private
        #
        # Tag field id
        TAG_FIELD_ID = 0

        # @private
        #
        # Serialized tag context limit
        TAG_MAP_SERIALIZED_SIZE_LIMIT = 8192

        # Serialize TagMap object
        #
        # @param [TagMap] tags_context
        #
        def serialize tags_context
          binary = [int_to_varint(VERSION_ID)]

          tags_context.each do |key, value|
            binary << int_to_varint(TAG_FIELD_ID)
            binary << int_to_varint(key.length)
            binary << key.encode(Encoding::UTF_8)
            binary << int_to_varint(value ? value.length : 0)
            binary << value.to_s.encode(Encoding::UTF_8)
          end

          binary = binary.join
          binary.length > TAG_MAP_SERIALIZED_SIZE_LIMIT ? nil : binary
        end

        # Deserialize binary data into a TagMap object.
        #
        # @param [String] binary
        # @return [TagMap]
        # @raise [BinaryFormatterError] If deserialized version id not valid or
        # tag key, value size in varint more then then unsigned int32.
        #
        def deserialize binary
          return TagMap.new if binary.nil? || binary.empty?

          io = StringIO.new binary
          version_id = io.getc.unpack("C").first
          unless version_id == VERSION_ID
            raise BinaryFormatterError, "invalid version id"
          end

          tag_map = TagMap.new

          loop do
            break if io.eof?
            tag_field_id = io.getc.unpack("C").first
            break unless tag_field_id == TAG_FIELD_ID

            key_length = varint_to_int io
            key = io.gets key_length
            value_length = varint_to_int io
            value = io.gets value_length
            tag_map[key] = value
          end

          io.close
          tag_map
        end

        private

        # Convert integer to Varint.
        # @see https://developers.google.com/protocol-buffers/docs/encoding#varints
        #
        # @param [Integer] int_val
        # @return [String]
        def int_to_varint int_val
          result = []
          loop do
            bits = int_val & 0x7F
            int_val >>= 7
            if int_val.zero?
              result << bits
              break
            else
              result << (0x80 | bits)
            end
          end
          result.pack "C*"
        end

        # Convert Varint bytes format to integer
        # @see https://developers.google.com/protocol-buffers/docs/encoding#varints
        #
        # @param [StringIO] io
        # @return [Integer]
        # @raise [BinaryFormatterError] If varint size more then unsigned int32
        #
        def varint_to_int io
          int_val = 0
          shift = 0

          loop do
            raise BinaryFormatterError, "varint too long" if shift >= 32
            byte = io.getbyte
            int_val |= (byte & 0x7F) << shift
            shift += 7
            return int_val if (byte & 0x80).zero?
          end
        end
      end
    end
  end
end
