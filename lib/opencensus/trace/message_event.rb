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
    # An event describing a message sent/received between Spans.
    #
    class MessageEvent < TimeEvent
      # Unknown event type.
      MESSAGE_EVENT_TYPE_UNSPECIFIED  = :TYPE_UNSPECIFIED

      # Indicates a sent message.
      MESSAGE_EVENT_TYPE_SENT         = :SENT

      # Indicates a received message.
      MESSAGE_EVENT_TYPE_RECEIVED     = :RECEIVED

      ##
      # The type of MessageEvent. Indicates whether the message was sent or
      # received.
      #
      # @return [Symbol]
      #
      attr_reader :type

      ##
      # An identifier for the MessageEvent's message that can be used to match
      # SENT and RECEIVED MessageEvents. For example, this field could
      # represent a sequence ID for a streaming RPC. It is recommended to be
      # unique within a Span.
      #
      # @return [Integer]
      #
      attr_reader :id

      ##
      # The number of uncompressed bytes sent or received.
      #
      # @return [Integer]
      #
      attr_reader :uncompressed_size

      ##
      # The number of compressed bytes sent or received. If zero, assumed to
      # be the same size as uncompressed.
      #
      # @return [Integer, nil]
      # 
      attr_reader :compressed_size

      ##
      # Create a new MessageEvent object.
      #
      # @private
      #
      def initialize type, id, uncompressed_size, compressed_size: nil, time: time
        super time: time
        @type = type
        @id = id
        @uncompressed_size = uncompressed_size
        @compressed_size = compressed_size
      end
    end
  end
end
