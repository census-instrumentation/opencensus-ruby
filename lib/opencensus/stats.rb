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


require "opencensus/stats/recorder"
require "opencensus/stats/view"
require "opencensus/stats/aggregation"
require "opencensus/stats/measure"
require "opencensus/stats/exporters"

module OpenCensus
  ##
  # The Stats module contains support for OpenCensus stats collection.
  #
  # OpenCensus allows users to create typed measures, record measurements,
  # aggregate the collected data, and export the aggregated data.
  #
  #
  module Stats
    STATS_CONTEXT_KEY = :__stats_context__

    class << self
      def stats_context= context
        OpenCensus::Context.set STATS_CONTEXT_KEY, context
      end

      def unset_stats_context
        OpenCensus::Context.unset STATS_CONTEXT_KEY
      end

      def stats_context
        OpenCensus::Context.get STATS_CONTEXT_KEY
      end

      def recorder
        self.stats_context ||= Recorder.new
      end

      def measure_int name:, unit:, description: nil
        Measure.new name: name, unit: unit, type: :int, description: description
      end

      def measure_float name:, unit:, description: nil
        Measure.new(
          name: name,
          unit: unit,
          type: :float,
          description: description
        )
      end

      def create_view \
          name:,
          measure:,
          aggregation:,
          description: nil,
          columns: nil
        View.new(
          name: name,
          measure: measure,
          aggregation: aggregation,
          description: description,
          columns: columns
        )
      end

      def sum_aggregation
        Aggregation.new :sum
      end

      def count_aggregation
        Aggregation.new :count
      end

      def distribution_aggregation buckets
        Aggregation.new :distribution, buckets: buckets
      end

      def last_value_aggregation
        Aggregation.new :last_value
      end
    end
  end
end
