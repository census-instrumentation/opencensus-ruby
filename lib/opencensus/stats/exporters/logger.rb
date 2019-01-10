# frozen_string_literal: true


require "logger"
require "json"

module OpenCensus
  module Stats
    module Exporters
      ##
      # The Logger exporter exports captured spans to a standard Ruby Logger
      # interface.
      #
      class Logger
        ##
        # Create a new Logger exporter
        #
        # @param [#log] logger The logger to write to.
        # @param [Integer] level The log level. This should be a log level
        #        defined by the Logger standard library. Default is
        #        `::Logger::INFO`.
        #
        def initialize logger, level: ::Logger::INFO
          @logger = logger
          @level = level
        end

        ##
        # Export the captured stats to the configured logger.
        #
        # @param [Array<ViewData>] views_data The captured stats data.
        #
        def export views_data
          stats_data = views_data.map { |vd| format_view_data(vd) }
          @logger.log @level, stats_data.to_json
          nil
        end

        private

        def format_view_data view_data
          {
            view: format_view(view_data.view),
            measure: format_measure(view_data.view.measure),
            aggregation: format_aggregation(view_data)
          }
        end

        def format_view view
          {
            name: view.name,
            columns: view.columns,
            description: view.description
          }
        end

        def format_measure measure
          {
            name: measure.name,
            unit: measure.unit,
            type: measure.type,
            description: measure.description
          }
        end

        def format_aggregation view_data
          {
            type: view_data.view.aggregation.class.name.downcase,
            start_time: view_data.start_time,
            end_time: view_data.end_time,
            data: view_data.data
          }
        end
      end
    end
  end
end
