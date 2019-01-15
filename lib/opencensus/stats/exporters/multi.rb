# Copyright 2018 OpenCensus Authors
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


require "delegate"

module OpenCensus
  module Stats
    module Exporters
      ##
      # The Multi exporter multiplexes captured stats to a set of delegate
      # exporters. It is useful if you need to export to more than one
      # destination. You may also use it as a "null" exporter by providing
      # no delegates.
      #
      # Multi delegates to an array of the exporter objects. You can manage
      # the list of exporters using any method of Array. For example:
      #
      #     multi = OpenCensus::Stats::Exporters::Multi.new
      #     multi.export(views_data)  # Does nothing
      #     multi << OpenCensus::Stats::Exporters::Logger.new
      #     multi.export(views_data)  # Exports to the logger
      #
      class Multi < SimpleDelegator
        ##
        # Create a new Multi exporter
        #
        # @param [Array<#export>] delegates An array of exporters
        #
        def initialize *delegates
          super(delegates.flatten)
        end

        ##
        # Pass the captured stats view data to the delegates.
        #
        # @param [Array<ViewData>] views_data The captured stats.
        #
        def export views_data
          each { |delegate| delegate.export views_data }
          nil
        end
      end
    end
  end
end
