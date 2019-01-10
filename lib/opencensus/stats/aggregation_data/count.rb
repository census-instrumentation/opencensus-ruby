# frozen_string_literal: true


module OpenCensus
  module Stats
    module AggregationData
      # # Count
      #
      # Counts number of measurements recorded.
      class Count
        # @return [Integer,Float] Current count value.
        attr_reader :value

        # @return [Time] The latest timestamp a new data point was recorded
        attr_reader :time

        # @private
        def initialize
          @value = 0
        end

        # Increment counter.
        # @param [Time] time Time of data point was recorded
        def add time
          @time = time
          @value += 1
        end
      end
    end
  end
end
