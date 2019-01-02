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


require "opencensus/stats/config"
require "opencensus/stats/recorder"
require "opencensus/stats/view"
require "opencensus/stats/aggregation"
require "opencensus/stats/measure_registry"
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
    ##
    # Internal key for storing the current stat recorder in the thread local
    # context.
    #
    # @private
    STATS_CONTEXT_KEY = :__stats_context__

    class << self
      ##
      # Sets the current thread-local Recorder, which governs the behavior
      # of the recorder creation methods of OpenCensus::Stats::Recorder.
      #
      # @param [Recorder] context
      def stats_context= context
        OpenCensus::Context.set STATS_CONTEXT_KEY, context
      end

      ##
      # Unsets the current thread-local SpanContext, disabling stats recorder
      # creation methods of OpenCensus::Stats::Recorder
      def unset_stats_context
        OpenCensus::Context.unset STATS_CONTEXT_KEY
      end

      # Get the current thread-local stats recoder context/
      # Returns `nil` if there is no current SpanContext.
      #
      # @return [Recorder, nil]
      def stats_context
        OpenCensus::Context.get STATS_CONTEXT_KEY
      end

      # Get recoder from the stats context. If stats context nil then create
      # new recorder and set into stats context.
      # @return [Recorder]
      def recorder
        self.stats_context ||= Recorder.new
      end

      # Create and register integer type measure into measure registry.
      #
      # @param [String] name Name of the measure.
      # @param [String] unit Unit of the measure. i.e "kb", "s", "ms"
      # @param [String] description Detail description
      # @return [Measure]
      def measure_int name:, unit:, description: nil
        MeasureRegistry.register(
          name: name,
          unit: unit,
          type: :int,
          description: description
        )
      end

      # Create and register float type measure into measure registry.
      #
      # @param [String] name Name of the measure.
      # @param [String] unit Unit of the measure. i.e "kb", "s", "ms"
      # @param [String] description Detail description
      # @return [Measure]
      def measure_float name:, unit:, description: nil
        MeasureRegistry.register(
          name: name,
          unit: unit,
          type: :float,
          description: description
        )
      end

      # Get list of registered measures
      # @return [Array<Measure>]
      def registered_measures
        MeasureRegistry.measures
      end

      # Creat3e measurement value for registered measure.
      #
      # @param [String] name Name of the registered measure
      # @param [Integer, Float] value Value of the measurement
      # @raise [ArgumentError] if givem measure is not register
      def create_measurement name, value
        measure = MeasureRegistry.get name
        return measure.measurement(value) if measure
        raise ArgumentError, "#{name} measure is not registered"
      end

      # Create a view
      #
      # @param [String] name
      # @param [Measure] measure
      # @param [Aggregation] aggregation
      # @param [Array<String>] columns
      # @param [String] description
      def create_view \
          name:,
          measure:,
          aggregation:,
          columns: nil,
          description: nil
        View.new(
          name: name,
          measure: measure,
          aggregation: aggregation,
          description: description,
          columns: columns
        )
      end

      # Create aggregation defination instance with type sum.
      # @return [Aggregation]
      def sum_aggregation
        Aggregation.new :sum
      end

      # Create aggregation defination instance with type count.
      # @return [Aggregation]
      def count_aggregation
        Aggregation.new :count
      end

      # Create aggregation defination instance with type distribution.
      # @param [Array<Integer>,Array<Float>] buckets Value boundries for
      # distribution.
      # @return [Aggregation]
      def distribution_aggregation buckets
        Aggregation.new :distribution, buckets: buckets
      end

      # Create aggregation defination instance with type last value.
      # @return [Aggregation]
      def last_value_aggregation
        Aggregation.new :last_value
      end
    end
  end
end
