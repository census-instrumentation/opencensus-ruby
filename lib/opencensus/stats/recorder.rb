# frozen_string_literal: true


require "opencensus/stats/view"
require "opencensus/stats/view_data"

module OpenCensus
  module Stats
    class Recorder
      attr_reader :views, :exporters, :measures, :measure_views_data

      def initialize
        @views = {}
        @measures = {}
        @exporters = []
        @measure_views_data = {}
        @time = Time.now.utc
      end

      def register_view view
        return if @views.key? view.name

        @views[view.name] = view
        @measures[view.measure.name] = view.measure

        unless @measure_views_data.key? view.measure.name
          @measure_views_data[view.measure.name] = []
        end

        @measure_views_data[view.measure.name] << ViewData.new(
          view,
          start_time: @time,
          end_time: @time
        )
      end

      def record *measurements, tags: nil
        return if measurements.any? { |m| m.value.negative? }
        tags ||= Tags.tags_context

        measurements.each do |measurement|
          next unless @measures.key? measurement.measure.name

          views_data = @measure_views_data[measurement.measure.name]
          views_data.each do |view_data|
            view_data.record tags, measurement.value, Time.now.utc
          end

          export views_data
        end
      end

      def view_data view_name
        view = @views[view_name]
        return unless view

        views_data = @measure_views_data[view.measure.name]
        views_data.find { |view_data| view_data.view.name == view.name }
      end

      def clear_stats
        @measure_views_data.each_value do |views_data|
          views_data.each(&:clear_stats)
        end
      end

      def register_exporter exporter
        @exporters << exporter
      end

      def unregister_exporter exporter
        @exporters.delete exporter
      end

      # TODO: implementation
      def export views_data
      end
    end
  end
end
