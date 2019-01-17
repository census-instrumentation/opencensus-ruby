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
    # Schema of the Trace configuration. See Stats#configure for more info.
    @config = Common::Config.new do |config|
      exporter_logger = ::Logger.new STDOUT, ::Logger::INFO
      default_exporter = Exporters::Logger.new exporter_logger

      config.add_option! :exporter, default_exporter do |value|
        value.respond_to? :export
      end
    end

    # Expose the stats config as a subconfig under the main config.
    OpenCensus.configure do |config|
      config.add_alias! :stats, config: @config
    end

    class << self
      ##
      # Configure OpenCensus Stats. These configuration fields include
      # parameters governing aggregation, exporting.
      #
      # This configuration is also available as the `stats` subconfig under the
      # main configuration `OpenCensus.configure`. If the OpenCensus Railtie is
      # installed in a Rails application, the configuration object is also
      # exposed as `config.opencensus.stats`.
      #
      # Generally, you should configure this once at process initialization,
      # but it can be modified at any time.
      #
      # Supported fields are:
      #
      # *   `exporter` The exporter to use. Must be an exporter, an object with
      #     an export method that takes an array of ViewData objects. See
      #     {OpenCensus::Stats::Exporters}. The initial value is a
      #     {OpenCensus::Stats::Exporters::Logger} that logs to STDOUT.
      #
      # @example:
      #
      #  OpenCensus::Stats.configure do |config|
      #    config.exporter = OpenCensus::Stats::Exporters::Logger.new
      #  end
      #
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
