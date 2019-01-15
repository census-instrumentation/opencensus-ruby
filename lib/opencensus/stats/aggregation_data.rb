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
    end
  end
end
