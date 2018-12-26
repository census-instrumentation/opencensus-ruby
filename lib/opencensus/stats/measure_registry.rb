# frozen_string_literal: true


require "singleton"
require "opencensus/stats/measure"

module OpenCensus
  module Stats
    class MeasureRegistry
      include Singleton

      attr_reader :measures

      def initialize
        @measures = {}
      end

      class << self
        def register name:, unit:, type:, description: nil
          return if instance.measures.key? name
          measure = Measure.new(
            name: name,
            unit: unit,
            type: type,
            description: description
          )

          instance.measures[name] = measure
        end

        def unregister name
          instance.measures.delete name
        end

        def clear
          instance.measures.clear
        end

        def get name
          instance.measures[name]
        end

        def measures
          instance.measures.values
        end
      end
    end
  end
end
