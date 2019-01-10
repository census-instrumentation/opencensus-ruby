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

      # @return [TagMap] The tags to which the value is applied
      attr_reader :tags

      # @return [Time] The time when measurement was created.
      attr_reader :time

      # Create a instance of measurement
      #
      # @param [Measure] measure A measure to which the value is applied.
      # @param [Integer,Float] value Measurement value.
      # @param [Hash<String,String>] tags The tags to which the value is applied
      def initialize measure:, value:, tags:
        @measure = measure
        @value = value
        @tags = Tags::TagMap.new tags
        @time = Time.now
      end
    end
  end
end
