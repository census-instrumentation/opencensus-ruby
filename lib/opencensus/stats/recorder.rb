# frozen_string_literal: true


require "opencensus/stats/view"
require "opencensus/stats/view_data"

module OpenCensus
  module Stats
    class Recorder
      attr_reader :views, :exporters

      def initialize
        @views = {}
        @measures = {}
        @exporters = []
        @measure_views_data = {}
        @time = Time.now.utc
      end

      def measure_int name, unit, description = nil
        Measure.new name, description, unit, :int
      end

      def measure_float name, unit, description = nil
        Measure.new name, description, unit, :float
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
        return if measurements.any?{|m| m.value.negative? }

        tags = Tags.tags_context unless tags

        measurements.each do |measurement|
          next unless @measures.key? measurement.measure.name

          views_data = @measure_views_data[measurement.measure.name]
          next unless views_data

          views_data.each do |view_data|
            view_data.record tags, measurement.value, Time.now.utc
          end

          export views_data
        end

        true
      end

      def view_data name
        view = @views[name]
        return unless view

        views_data = @measure_views_data[view.measure.name]
        return unless views_data

        views_data.find{|view_data| view_data.view.name == view.name }
      end

      def clear_stats
        @measure_views_data.each_value do |views_data|
          views_data.each &:clear_stats
        end
      end

      def register_exporter exporter
        @exporters << exporter
      end

      def unregister_exporter exporter
        @exporters.delete exporter
      end

      def export view_datas
      end
    end
  end
end
