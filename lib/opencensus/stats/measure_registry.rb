# frozen_string_literal: true


require "singleton"
require "opencensus/stats/measure"

module OpenCensus
  module Stats
    # #MeasureRegistry
    #
    # Measure registry is a collection of uniq measures.
    #
    class MeasureRegistry
      include Singleton

      # @return [Hash<String, Measure>]
      attr_reader :measures

      # @private
      def initialize
        @measures = {}
      end

      class << self
        # Register measure.
        #
        # @param [String] name Name of measure
        # @param [String] unit Unit name of measure
        # @param [String] type Date type unit of measure. integer or float.
        # @param [String] description Description of measure
        # @return [Measure, nil]
        #
        def register name:, unit:, type:, description: nil
          return if instance.measures.key? name

          raise if type ==

          measure = Measure.new(
            name: name,
            unit: unit,
            type: type,
            description: description
          )

          instance.measures[name] = measure
        end

        # Un register measure
        #
        # @param [String] name Name of the registered view
        def unregister name
          instance.measures.delete name
        end

        # Clear measures registry
        def clear
          instance.measures.clear
        end

        # Get registered measure
        # @return [Measure]
        def get name
          instance.measures[name]
        end

        # List of registered measures
        # @return [Array<Measure>]
        def measures
          instance.measures.values
        end
      end
    end
  end
end
