# frozen_string_literal: true


module OpenCensus
  module Stats
    module Aggregation
      # Sum aggregation type
      class Sum
        # Create new aggregation data container to store sum value
        # values.
        # @return [AggregationData::Sum]
        def create_aggregation_data
          AggregationData::Sum.new
        end
      end
    end
  end
end
