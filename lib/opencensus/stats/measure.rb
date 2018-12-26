# frozen_string_literal: true


require "opencensus/stats/measurement"

module OpenCensus
  module Stats
    class Measure
      # Describes the unit used for the Measure.
      # Should follows the format described by
      # http://unitsofmeasure.org/ucum.html
      UNIT_NONE = "1" # for general counts
      BYTE = "By"
      KBYTE = "kb"
      SEC = "s"
      MS = "ms"
      NS = "ns"

      attr_reader :name, :description, :unit, :type

      def initialize name:, unit:, type:, description: nil
        @name = name
        @unit = unit
        @type = type
        @description = description
      end

      def measurement value
        Measurement.new(self, value)
      end

      def int?
        type == :int
      end

      def float?
        type == :float
      end
    end
  end
end
