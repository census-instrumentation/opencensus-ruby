# frozen_string_literal: true


require "opencensus/stats/aggregation/sum"
require "opencensus/stats/aggregation/count"
require "opencensus/stats/aggregation/last_value"
require "opencensus/stats/aggregation/distribution"
require "opencensus/stats/aggregation_data"

module OpenCensus
  module Stats
    # # Aggregation
    #
    # Aggregation types to describes how the data collected based on aggregation
    # type.
    # Aggregation types are.
    # - Sum
    # - Count
    # - Last Value
    # - Distribution - calcualate min, max, mean, sum, count,
    #   sum of squared deviation
    #
    module Aggregation
    end
  end
end
