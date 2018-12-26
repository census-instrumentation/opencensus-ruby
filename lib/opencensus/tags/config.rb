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


require "opencensus/config"
require "opencensus/tags/formatters"

module OpenCensus
  module Tags
    @config = Common::Config.new do |config|
      default_formatter = Formatters::Binary.new
      config.add_option! :binary_formatter, default_formatter do |value|
        value.respond_to?(:serialize) && value.respond_to?(:deserialize)
      end
    end

    OpenCensus.configure do |config|
      config.add_alias! :tags, config: @config
    end

    class << self
      def configure
        if block_given?
          yield @config
        else
          @config
        end
      end

      ##
      # Get the current configuration
      # @private
      #
      attr_reader :config
    end
  end
end
