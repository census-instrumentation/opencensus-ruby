# frozen_string_literal: true

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
require "opencensus/stats/exporters"

module OpenCensus
  module Stats
    @config = Common::Config.new do |config|
      exporter_logger = ::Logger.new STDOUT, ::Logger::INFO
      default_exporter = Exporters::Logger.new exporter_logger

      config.add_option! :exporter, default_exporter do |value|
        value.respond_to? :export
      end
    end

    OpenCensus.configure do |config|
      config.add_alias! :stats, config: @config
    end

    class << self
      def configure
        if block_given?
          yield @config
        else
          @config
        end
      end

      attr_reader :config
    end
  end
end
