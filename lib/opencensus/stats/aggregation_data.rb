# frozen_string_literal: true


require "opencensus/stats/aggregation_data/sum"
require "opencensus/stats/aggregation_data/count"
require "opencensus/stats/aggregation_data/last_value"
require "opencensus/stats/aggregation_data/distribution"

module OpenCensus
  module Stats
    # # AggregationData
    #
    # AggregationData to store collected stats data.
    # Aggregation data container type:
    # - Sum
    # - Count
    # - Last Value
    # - Distribution - calcualate sum, count, min, max, mean,
    #   sum of squared deviation
    #
    module AggregationData
      # Add value to aggregation data based on type.
      #
      # @param [Distribution,Sum,LastValue,Count] aggregation_data
      # @param [Integer,Float] value
      # @param [Time] time Time of data point was recorded
      def self.add aggregation_data, value, time
        case aggregation_data
        when Distribution
          aggregation_data.add value, time
        when Sum, LastValue
          aggregation_data.add value, time
        when Count
          aggregation_data.add time
        end
      end
    end
  end
end
