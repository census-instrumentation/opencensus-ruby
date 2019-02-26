# frozen_string_literal: true


module OpenCensus
  module Stats
    module AggregationData
      # Sum
      #
      # Accumulate measurement values.
      class Sum
        # @return [Integer,Float] The current sum value.
        attr_reader :value

        # @return [Time] The latest time at new data point was recorded
        attr_reader :time

        # @private
        def initialize
          @value = 0
        end

        # rubocop:disable Lint/UnusedMethodArgument

        # Add value
        # @param [Integer,Float] value
        # @param [Time] time Time of data point was recorded
        def add value, time, attachments: nil
          @time = time
          @value += value
        end

        # rubocop:enable Lint/UnusedMethodArgument
      end
    end
  end
end
