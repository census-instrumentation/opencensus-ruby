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

        # rubocop:disable Lint/UnusedMethodArgument

        # Set last value
        # @param [Integer,Float] value
        # @param [Time] time Time of data point was recorded
        def add value, time, attachments: nil
          @time = time
          @value = value
        end

        # rubocop:enable Lint/UnusedMethodArgument
      end
    end
  end
end
