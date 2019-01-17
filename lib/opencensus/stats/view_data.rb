# frozen_string_literal: true


module OpenCensus
  module Stats
    # ViewData is a container to store stats.
    class ViewData
      # @return [View]
      attr_reader :view

      # @return [Time, nil]
      attr_reader :start_time

      # @return [Time, nil]
      attr_reader :end_time

      # @return [Hash<Array<String>>,AggregationData] Recorded stats data
      # against view columns.
      attr_reader :data

      # @private
      # Create instance of view
      #
      # @param [View] view
      # @param [Time] start_time
      # @param [Time] end_time
      def initialize view, start_time: nil, end_time: nil
        @view = view
        @start_time = start_time
        @end_time = end_time
        @data = {}
      end

      # Set start time.
      def start
        @start_time = Time.now.utc
      end

      # Set stop time.
      def stop
        @end_time = Time.now.utc
      end

      # Record a measurement.
      #
      # @param [Measurement] measurement
      def record measurement
        tag_values = @view.columns.map { |column| measurement.tags[column] }

        unless @data.key? tag_values
          @data[tag_values] = @view.aggregation.create_aggregation_data
        end

        @data[tag_values].add measurement.value, measurement.time
      end

      # Clear recorded ata
      def clear
        data.clear
      end
    end
  end
end
