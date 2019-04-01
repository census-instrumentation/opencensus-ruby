# frozen_string_literal: true


module OpenCensus
  module Stats
    # Measurement
    #
    # Describes a data point to be collected for a Measure.
    class Measurement
      # @return [Measure] A measure to which the value is applied.
      attr_reader :measure

      # @return [Integer,Float] The recorded value
      attr_reader :value

      # @return [Tags::TagMap] The collection of tags to which the value is
      #   applied
      attr_reader :tags

      # @return [Time] The time when measurement was created.
      attr_reader :time

      # Create a instance of measurement
      #
      # @param [Measure] measure A measure to which the value is applied.
      # @param [Integer, Float] value Measurement value.
      # @param [Tags::TagMap, nil] tags The tags to which the value is applied
      def initialize measure:, value:, tags: nil
        @measure = measure
        @value = value
        @tags = tags || Tags::TagMap.new
        @time = Time.now.utc
      end
    end
  end
end
