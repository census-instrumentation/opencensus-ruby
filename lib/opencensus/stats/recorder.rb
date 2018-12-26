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
        return if tags.nil? || tags.empty?

        measurements.each do |measurement|
          next unless @measures.key? measurement.measure.name

          views_data = @measure_views_data[measurement.measure.name]
          views_data.each do |view_data|
            view_data.record tags, measurement.value, Time.now.utc
          end
        end
      end

      def view_data view_name
        view = @views[view_name]
        return unless view

        views_data = @measure_views_data[view.measure.name]
        views_data.find { |view_data| view_data.view.name == view.name }
      end

      def views_data
        @measure_views_data.values.flatten
      end

      def clear_stats
        @measure_views_data.each_value do |views_data|
          views_data.each(&:clear_stats)
        end
      end
    end
  end
end
