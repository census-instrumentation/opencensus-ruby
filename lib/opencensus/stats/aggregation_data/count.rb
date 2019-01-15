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

        # rubocop:disable Lint/UnusedMethodArgument

        # Increment counter.
        # @param [Value] value
        # @param [Time] time Time of data point was recorded
        def add value, time
          @time = time
          @value += 1
        end

        # rubocop:enable Lint/UnusedMethodArgument
      end
    end
  end
end
