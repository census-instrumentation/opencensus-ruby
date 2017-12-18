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
    ##
    # A string that might be shortened to a specified length.
    #
    class TruncatableString
      ##
      # The shortened string. For example, if the original string was 500 bytes
      # long and the limit of the string was 128 bytes, then this value contains
      # the first 128 bytes of the 500-byte string. Note that truncation always
      # happens on a character boundary, to ensure that a truncated string is
      # still valid UTF-8. Because it may contain multi-byte characters, the
      # size of the truncated string may be less than the truncation limit.
      #
      # @return [String]
      #
      attr_reader :value

      ##
      # The number of bytes removed from the original string. If this value is
      # 0, then the string was not shortened.
      #
      # @return [Fixnum]
      #
      attr_reader :truncated_byte_count

      ##
      # Create an empty TruncatableString object.
      #
      # @private
      #
      def initialize value: nil, truncated_byte_count: 0
        @value = value
        @truncated_byte_count = truncated_byte_count
      end
    end
  end
end
