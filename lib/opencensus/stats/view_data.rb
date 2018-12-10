# frozen_string_literal: true

module OpenCensus
  module Stats
    class ViewData
      attr_reader :view, :start_time, :end_time, :data

      def initialize view, start_time: nil, end_time: nil
        @view = view
        @start_time = start_time
        @end_time = end_time
        @data = {}
      end

      def start
        @start_time = Time.now.utc
      end

      def stop
        @end_time = Time.now.utc
      end

      def record tags, value, timestamp
        tag_values = view.columns.map { |key| tags[key] }

        unless data.key? tag_values
          data[tag_values] = view.aggregation.new_aggregation_data
        end

        data[tag_values].add value, timestamp: timestamp
      end

      def clear_stats
        data.clear
      end
    end
  end
end
