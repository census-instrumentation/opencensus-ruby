# frozen_string_literal: true


require "opencensus/stats/measurement"

module OpenCensus
  module Stats
    # Measure
    #
    # The definition of the Measurement.
    class Measure
      # Describes the unit used for the Measure.
      # Should follows the format described by
      # http://unitsofmeasure.org/ucum.html
      # Unit name for general counts
      # @return [String]
      UNIT_NONE = "1".freeze

      # Unit name for bytes
      # @return [String]
      BYTE = "By".freeze

      # Unit name for Kilobytes
      # @return [String]
      KBYTE = "kb".freeze

      # Unit name for Seconds
      # @return [String]
      SEC = "s".freeze

      # Unit name for Micro seconds
      # @return [String]
      MS = "ms".freeze

      # Unit name for Neno seconds
      # @return [String]
      NS = "ns".freeze

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :description

      # Unit type of the measurement. i.e "kb", "ms" etc
      # @return [String]
      attr_reader :unit

      # Data type of the measure.
      # @return [String]
      attr_reader :type

      # @private
      # Create instance of the measure.
      def initialize name:, unit:, type:, description: nil
        @name = name
        @unit = unit
        @type = type
        @description = description
      end

      # Create new measurement
      # @param [Integer, Float] value
      # @return [Measurement]
      def measurement value
        Measurement.new(self, value)
      end

      # Is integer data type
      # @return [Boolean]
      def int?
        type == :int
      end

      # Is float data type
      # @return [Boolean]
      def float?
        type == :float
      end
    end
  end
end
