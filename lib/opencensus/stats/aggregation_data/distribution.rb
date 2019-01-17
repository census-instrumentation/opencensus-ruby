# frozen_string_literal: true


module OpenCensus
  module Stats
    module AggregationData
      # # Distribution
      #
      # This AggregationData contains a histogram of the collected values
      class Distribution
        # @return [Array<Integer>,Array<Float>] Buckets boundries
        attr_reader :buckets

        # @return [Integer] Count of recorded values
        attr_reader :count

        # @return [Integer,Float] Sum of recorded values
        attr_reader :sum

        # @return [Integer,Float] Maximum recorded value
        attr_reader :max

        # @return [Integer,Float] Minimum recorded value
        attr_reader :min

        # @return [Integer,Float] Mean of recorded values
        attr_reader :mean

        # @return [Integer,Float] Sum of squared deviation of recorded values
        attr_reader :sum_of_squared_deviation

        # @return [Array<Integer>] Count of number of recorded values in buckets
        attr_reader :bucket_counts

        # @return [Time] Time of first recorded value
        attr_reader :start_time

        # @return [Time] The latest time a new value was recorded
        attr_reader :time

        # @private
        # @param [Array<Integer>,Array<Float>] buckets Buckets boundries
        # for distribution
        def initialize buckets
          @buckets = buckets
          @count = 0
          @sum = 0
          @max = -Float::INFINITY
          @min = Float::INFINITY
          @mean = 0
          @sum_of_squared_deviation = 0
          @bucket_counts = Array.new(buckets.length + 1, 0)
          @start_time = Time.now.utc
        end

        # @private
        # Add value to distribution
        # @param [Integer,Float] value
        # @param [Time] time Time of data point was recorded
        def add value, time
          @time = time
          @count += 1
          @sum += value
          @max = value if value > @max
          @min = value if value < @min

          delta_from_mean = (value - @mean).to_f
          @mean += delta_from_mean / @count
          @sum_of_squared_deviation += delta_from_mean * (value - @mean)

          bucket_index = @buckets.find_index { |b| b > value } ||
                         @buckets.length
          @bucket_counts[bucket_index] += 1
        end

        # Get distribution result values.
        # @return [Hash]
        def value
          {
            start_time: @start_time,
            count: @count,
            sum: @sum,
            max: @max,
            min: @min,
            sum_of_squared_deviation: @sum_of_squared_deviation,
            buckets: @buckets,
            bucket_counts: @bucket_counts
          }
        end
      end
    end
  end
end
