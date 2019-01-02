# frozen_string_literal: true


require "opencensus/stats/view"
require "opencensus/stats/view_data"

module OpenCensus
  module Stats
    # Stats recorder.
    #
    # Recorder record measurement against measure for registered views
    # Span represents a span in a trace record. Spans are contained in
    # a trace and arranged in a forest. That is, each span may be a root span
    # or have a parent span, and may have zero or more children.
    class Recorder
      # @private
      # @return [Hash<String,View>] Hash of view name and View object.
      attr_reader :views

      # @private
      # @return [Hash<String,Measure>] Hash of measure name and Measure object.
      attr_reader :measures

      # @private
      # @return [Hash<String,Array<<ViewData>>]
      # Hash of view name and View data objects array.
      attr_reader :measure_views_data

      # @private
      # Create instance of the recorder.
      def initialize
        @views = {}
        @measures = {}
        @measure_views_data = {}
        @time = Time.now.utc
      end

      # Register view
      #
      # @param [View] view
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

      # Record measurements
      #
      # @param [Array<Measurement>, Measurement] measurements
      # @param [TagMap] tags
      def record *measurements, tags: nil
        return if measurements.any? { |m| m.value < 0 }
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

      # Get recorded data for given view name
      #
      # @param [String] view_name View name
      # @return [ViewData]
      def view_data view_name
        view = @views[view_name]
        return unless view

        views_data = @measure_views_data[view.measure.name]
        views_data.find { |view_data| view_data.view.name == view.name }
      end

      # Get all views data list
      # @return [Array<ViewData>]
      def views_data
        @measure_views_data.values.flatten
      end

      # Clear recorded stats.
      def clear_stats
        @measure_views_data.each_value do |views_data|
          views_data.each(&:clear)
        end
      end
    end
  end
end
