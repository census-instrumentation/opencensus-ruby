# frozen_string_literal: true


module OpenCensus
  module Stats
    module Aggregation
      # Count aggregation type
      class Count
        # Create new aggregation data container to store count value.
        # values.
        # @return [AggregationData::Count]
        def create_aggregation_data
          AggregationData::Count.new
        end
      end
    end
  end
end
