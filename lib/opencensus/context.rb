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
  ##
  # The Context module provides per-thread storage.
  #
  module Context
    ##
    # Thread local storage key under which all OpenCensus context data is
    # stored.
    #
    # @private
    #
    THREAD_KEY = :__opencensus_context__

    class << self
      ##
      # Store a value in the context.
      #
      # @param [String, Symbol] key The name of the context value to store.
      # @param [Object] value The value associated with the key.
      def set key, value
        storage[key] = value
      end

      ##
      # Return a value from the context. Returns nil if no value is set.
      #
      # @param [String, Symbol] key The name of the context value to fetch.
      # @return [Object, nil] The fetched value.
      #
      def get key
        storage[key]
      end

      ##
      # Unsets a value from the context.
      #
      # @param [String, Symbol] key The name of the context value to unset.
      # @return [Object, nil] The value of the context value just unset.
      #
      def unset key
        storage.delete key
      end

      ##
      # Clears all values from the context.
      #
      def reset!
        Thread.current[THREAD_KEY] = {}
      end

      private

      def storage
        Thread.current[THREAD_KEY] ||= {}
      end
    end
  end
end
