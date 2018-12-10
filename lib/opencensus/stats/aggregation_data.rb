# frozen_string_literal: true

module OpenCensus
  module Stats
    class AggregationData
      attr_reader :type, :data

      def initialize type, buckets: nil
        @type = type

        case type
        when :sum, :count
          @data = 0
        when :distribution
          @data = {
            count: 0,
            sum: 0,
            max: -Float::INFINITY,
            min: Float::INFINITY,
            mean: 0,
            sum_of_squared_deviation: 0,
            buckets: buckets,
            bucket_counts: Array.new(buckets.length + 1, 0)
          }
        end
      end

      def add value, timestamp: nil
        case type
        when :sum
          @data += value
        when :count
          @data += 1
        when :distribution
          add_distribution value
        when :last_value
          @data = value
        end
      end

      def add_distribution value
        @data[:count] += 1
        @data[:sum] += value
        @data[:max] = value if value > @data[:max]
        @data[:min] = value if value < @data[:min]

        bucket_index = @data[:buckets].find_index { |b| b > value }
        bucket_index ||= @data[:buckets].length
        @data[:bucket_counts][bucket_index] += 1

        delta_from_mean = (value - @data[:mean]).to_f
        @data[:mean] += delta_from_mean / @data[:count]
        @data[:sum_of_squared_deviation] +=
          delta_from_mean * (value - @data[:mean])
      end
    end
  end
end
