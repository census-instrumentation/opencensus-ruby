# frozen_string_literal: true


module OpenCensus
  module Stats
    # @private
    #
    # ViewData is a container to store stats.
    class ViewData
      attr_reader :view, :start_time, :end_time, :data

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

      # Record value
      #
      # @param [TagMap] tags
      # @param [Integer, Float] value
      # @param [Time] timestamp
      def record tags, value, timestamp
        tag_values = view.columns.map { |key| tags[key] }

        unless data.key? tag_values
          data[tag_values] = view.aggregation.new_aggregation_data
        end

        data[tag_values].add value, timestamp: timestamp
      end

      # Clear recorded ata
      def clear
        data.clear
      end
    end
  end
end
