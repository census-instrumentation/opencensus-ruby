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
    # Internal key for storing the current stats recorder in the thread local
    # context.
    #
    # @private
    RECORDER_CONTEXT_KEY = :__recorder_context__

    class << self
      ##
      # Sets the current thread-local Recorder, which governs the behavior
      # of the recorder creation methods of OpenCensus::Stats::Recorder.
      #
      # @param [Recorder] context
      def recorder_context= context
        OpenCensus::Context.set RECORDER_CONTEXT_KEY, context
      end

      ##
      # Unsets the current thread-local SpanContext, disabling stats recorder
      # creation methods of OpenCensus::Stats::Recorder
      def unset_recorder_context
        OpenCensus::Context.unset RECORDER_CONTEXT_KEY
      end

      # Get the current thread-local stats recorder context/
      # Returns `nil` if there is no current SpanContext.
      #
      # @return [Recorder, nil]
      def recorder_context
        OpenCensus::Context.get RECORDER_CONTEXT_KEY
      end

      # Get recorder from the stats context. If stats context nil then create
      # new recorder and set into stats context.
      # @return [Recorder]
      def ensure_recorder
        self.recorder_context ||= Recorder.new
      end

      # Create and register int64 type measure into measure registry.
      #
      # @param [String] name Name of the measure.
      # @param [String] unit Unit of the measure. i.e "kb", "s", "ms"
      # @param [String] description Detail description
      # @return [Measure]
      def create_measure_int name:, unit:, description: nil
        MeasureRegistry.register(
          name: name,
          unit: unit,
          type: Measure::INT64_TYPE,
          description: description
        )
      end

      # Create and register double type measure into measure registry.
      #
      # @param [String] name Name of the measure.
      # @param [String] unit Unit of the measure. i.e "kb", "s", "ms"
      # @param [String] description Detail description
      # @return [Measure]
      def create_measure_double name:, unit:, description: nil
        MeasureRegistry.register(
          name: name,
          unit: unit,
          type: Measure::DOUBLE_TYPE,
          description: description
        )
      end

      # Get list of registered measures
      # @return [Array<Measure>]
      def registered_measures
        MeasureRegistry.measures
      end

      # Create measurement value for registered measure.
      #
      # @param [String] name Name of the registered measure
      # @param [Integer, Float] value Value of the measurement
      # @param [Tags::TagMap] tags A map of tags to which the value is recorded.
      #   Tags could either be explicitly passed, or implicitly read from
      #   current tags context.
      # @raise [ArgumentError]
      #   if given measure is not register.
      #   if given tags are nil and tags global context is nil.
      def create_measurement name:, value:, tags: nil
        measure = MeasureRegistry.get name

        unless measure
          raise ArgumentError, "#{name} measure is not registered"
        end

        tags = OpenCensus::Tags.tag_map_context unless tags
        raise ArgumentError, "pass tags or set tags global context" unless tags

        measure.create_measurement value: value, tags: tags
      end

      # Create and register a view to current stats recorder context.
      #
      # @param [String] name
      # @param [Measure] measure
      # @param [Aggregation] aggregation
      # @param [Array<String>] columns
      # @param [String] description
      def create_and_register_view \
          name:,
          measure:,
          aggregation:,
          columns: nil,
          description: nil
        view = View.new(
          name: name,
          measure: measure,
          aggregation: aggregation,
          description: description,
          columns: columns
        )
        ensure_recorder.register_view view
      end

      # Create aggregation defination instance with type sum.
      # @return [Aggregation]
      def create_sum_aggregation
        Aggregation::Sum.new
      end

      # Create aggregation defination instance with type count.
      # @return [Aggregation]
      def create_count_aggregation
        Aggregation::Count.new
      end

      # Create aggregation defination instance with type distribution.
      # @param [Array<Integer>,Array<Float>] buckets Value boundries for
      # distribution.
      # @return [Aggregation]
      def create_distribution_aggregation buckets
        Aggregation::Distribution.new buckets
      end

      # Create aggregation defination instance with type last value.
      # @return [Aggregation]
      def create_last_value_aggregation
        Aggregation::LastValue.new
      end
    end
  end
end
