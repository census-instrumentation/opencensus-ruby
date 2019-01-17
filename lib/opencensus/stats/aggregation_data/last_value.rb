# frozen_string_literal: true


module OpenCensus
  module Stats
    module AggregationData
      # # LastValue
      #
      # Represents the last recorded value.
      class LastValue
        # @return [Integer,Float] Last recorded value.
        attr_reader :value

        # @return [Time] The latest time at new data point was recorded
        attr_reader :time

        # Set last value
        # @param [Integer,Float] value
        # @param [Time] time Time of data point was recorded
        def add value, time
          @time = time
          @value = value
        end
      end
    end
  end
end
