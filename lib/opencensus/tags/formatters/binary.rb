# frozen_string_literal: true

module OpenCensus
  module Tags
    module Formatters
      class Binary
        # @private
        class BinaryFormatterError < StandardError; end

        VERSION_ID = 0
        TAG_FIELD_ID = 0
        TAG_MAP_SERIALIZED_SIZE_LIMIT = 8192

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

        def deserialize binary
          return TagMap.new if binary.nil? || binary.empty?

          io = StringIO.new binary
          version_id = io.getc.unpack1("C")
          unless version_id == VERSION_ID
            raise BinaryFormatterError, "invalid version id"
          end

          tag_map = TagMap.new

          loop do
            break if io.eof?
            tag_field_id = io.getc.unpack1("C")
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
