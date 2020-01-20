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


require "forwardable"
require "opencensus/tags/tag"

module OpenCensus
  module Tags
    # # TagMap
    #
    # Collection of tags that can be used to label anything that is
    # associated with a stats or trace operations.
    #
    # @example
    #
    #  tag_map = OpenCensus::Tags::TagMap.new
    #
    #  # Add tag
    #  tag_map << OpenCensus::Tags::Tag.new "key1", "val1"
    #
    #  # Add tag with TagTTL
    #  tag_map << OpenCensus::Tags::Tag.new "key2", "val2", ttl: 0
    #
    #  # Update tag
    #  tag_map << OpenCensus::Tags::Tag.new "key3", "val3"
    #  tag_map << OpenCensus::Tags::Tag.new "key3", "updatedval3"
    #
    #  # Get tag by key
    #  p tag_map["key1"]
    #  # <OpenCensus::Tags::Tag:0x007ffc138 @key="key1", @value="val1", @ttl=-1>
    #
    #  # Delete
    #  tag_map.delete "key1"
    #
    #  # Iterate
    #  tag_map.each do |tag|
    #    p tag.key
    #    p tag.value
    #  end
    #
    #  # Length
    #  tag_map.length # 1
    #
    # @example Create tag map from hash
    #
    #   tag_map = OpenCensus::Tags::OpenCensus.new({
    #     "key1" => "val1",
    #     "key2" => "val2"
    #   })
    #
    # @example Create tag map with list of tags.
    #
    #   tag_map = OpenCensus::Tags::OpenCensus.new([
    #     OpenCensus::Tags::Tag.new "key1", "val1",
    #     OpenCensus::Tags::Tag.new "key2", "val2"
    #   ])
    #
    class TagMap
      extend Forwardable

      # Create a tag map.
      #
      # @param [Hash<String,String>, Array<Tags::Tag>, nil] tags Tags list with
      #   string key and value and metadata.
      def initialize tags = nil
        @tags = case tags
                when Hash
                  tags.each_with_object({}) do |(key, value), r|
                    tag = Tag.new key, value
                    r[tag.key] = tag
                  end
                when Array
                  tags.each_with_object({}) { |tag, r| r[tag.key] = tag }
                else
                  {}
                end
      end

      # Insert tag.
      #
      # @param [Tag] tag
      def << tag
        @tags[tag.key] = tag
      end

      # Get all tags
      #
      # @return [Array<Tag>]
      def tags
        @tags.values
      end

      # Get tag by key
      #
      # @return [Tag, nil]
      def [] key
        @tags[key]
      end

      # Delete tag by key
      # @param [String] key Tag key
      def delete key
        @tags.delete key
      end

      # @!method each
      #   @see Hash#each
      # @!method length
      #   @see Hash#length
      # @!method empty?
      #   @see Hash#empty?
      def_delegators :@tags, :each, :length, :empty?

      # Convert tag map to binary string format.
      #
      # @see [documentation](https://github.com/census-instrumentation/opencensus-specs/blob/master/encodings/BinaryEncoding.md#tag-context)
      # @return [String] Binary string
      #
      def to_binary
        Formatters::Binary.new.serialize self
      end

      # Create a tag map from the binary string.
      #
      # @param [String] data Binary string data
      # @return [TagMap]
      #
      def self.from_binary data
        Formatters::Binary.new.deserialize data
      end
    end
  end
end
