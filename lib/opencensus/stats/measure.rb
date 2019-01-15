# frozen_string_literal: true


require "opencensus/stats/measurement"

module OpenCensus
  module Stats
    # Measure
    #
    # The definition of the Measurement. Describes the type of the individual
    # values/measurements recorded by an application. It includes information
    # such as the type of measurement, the  units of measurement and descriptive
    # names for the data. This provides th fundamental type used for recording
    # data.
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

      # Unit name for Milli seconds
      # @return [String]
      MS = "ms".freeze

      # Unit name for Micro seconds
      # @return [String]
      US = "us".freeze

      # Unit name for Nano seconds
      # @return [String]
      NS = "ns".freeze

      # Measure int64 type
      # @return [String]
      INT64_TYPE = "INT64".freeze

      # Measure double type
      # @return [String]
      DOUBLE_TYPE = "DOUBLE".freeze

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :description

      # Unit type of the measurement. i.e "kb", "ms" etc
      # @return [String]
      attr_reader :unit

      # Data type of the measure.
      # @return [String] Valid types are {INT64_TYPE}, {DOUBLE_TYPE}.
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
      # @param [Hash<String,String>] tags Tags to which the value is recorded
      # @return [Measurement]
      def create_measurement value:, tags:
        Measurement.new measure: self, value: value, tags: tags
      end

      # Is int64 data type
      # @return [Boolean]
      def int64?
        type == INT64_TYPE
      end

      # Is float data type
      # @return [Boolean]
      def double?
        type == DOUBLE_TYPE
      end
    end
  end
end
