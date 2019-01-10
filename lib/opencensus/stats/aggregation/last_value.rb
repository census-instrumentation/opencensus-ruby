# frozen_string_literal: true


module OpenCensus
  module Stats
    module Aggregation
      # Last value aggregation type
      class LastValue
        # Create new aggregation data container to store last value.
        # values.
        # @return [AggregationData::LastValue]
        def create_aggregation_data
          AggregationData::LastValue.new
        end
      end
    end
  end
end
