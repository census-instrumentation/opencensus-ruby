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
    # The `Status` type defines a logical error model that is suitable for
    # different programming environments, including REST APIs and RPC APIs.
    # This Trace's fields are a subset of those of
    # [google.rpc.Status](https://github.com/googleapis/googleapis/blob/master/google/rpc/status.Trace),
    # which is used by [gRPC](https://github.com/grpc).
    class Status
      ##
      # The status code.
      #
      # @return [Fixnum]
      #
      attr_reader :code

      ##
      # A developer-facing error message, which should be in English.
      #
      # @return [String]
      #
      attr_reader :message

      ##
      # Create an empty Status object.
      #
      # @private
      #
      def initialize code: nil, message: nil
        @code = code
        @message = message
      end

    end
  end
end
