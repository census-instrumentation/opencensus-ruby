# frozen_string_literal: true


require "opencensus/stats/aggregation_data"

module OpenCensus
  module Stats
    class Aggregation
      attr_reader :type, :buckets

      # @private
      def initialize type, buckets: nil
        @type = type
        @buckets = buckets
      end

      def new_aggregation_data
        AggregationData.new type, buckets: buckets
      end
    end
  end
end
