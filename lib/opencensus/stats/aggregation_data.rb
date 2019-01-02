# frozen_string_literal: true

module OpenCensus
  module Stats
    ##
    # AggregationData container to store collected stats data.
    #
    # aggregation types:
    #   1. Sum
    #   2. Count
    #   3. Last value
    #   4. Distribution - count, sum, min, max, mean, sum of squared deviation
    #
    class AggregationData
      # @return [Symbol] Aggregation type.
      attr_reader :type

      # @return [Integer,Float,Hash,nil] Aggregated data.
      attr_reader :data

      # @return [Time, Nil] Last recorded time.
      attr_reader :timestamp

      # @private
      # Create new aggregation data collection instance.
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

      # Add value to aggregated data
      # @param [Integer, Float] value
      # @param [Time] timestamp
      def add value, timestamp: nil
        @timestamp = timestamp

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

      private

      # @private
      # Calculate count, sum, max, min, mean, sum of squared deviation.
      # @param [Integer,Float] value
      def add_distribution value
        @data[:count] += 1
        @data[:sum] += value
        @data[:max] = value if value > @data[:max]
        @data[:min] = value if value < @data[:min]

        delta_from_mean = (value - @data[:mean]).to_f
        @data[:mean] += delta_from_mean / @data[:count]
        @data[:sum_of_squared_deviation] +=
          delta_from_mean * (value - @data[:mean])

        bucket_index = @data[:buckets].find_index { |b| b > value } ||
                       @data[:buckets].length
        @data[:bucket_counts][bucket_index] += 1
      end
    end
  end
end
