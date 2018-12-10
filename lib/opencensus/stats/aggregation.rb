# frozen_string_literal: true


require "opencensus/stats/aggregation_data"

module OpenCensus
  module Stats
    class Aggregation
      attr_reader :type, :buckets

      # @private
      def initialize type, buckets: nil
        @type = type

        if type == :distribution
          validate_buckets! buckets
          @buckets = buckets
        end
      end

      def new_aggregation_data
        AggregationData.new type, buckets: buckets
      end

      private

      # @private
      class InvaliedBucketsError < StandardError; end

      def validate_buckets! buckets
        if buckets.nil?
          raise InvaliedBucketsError, "buckets should not be nil"
        end

        if buckets.any?(&:nil?)
          raise InvaliedBucketsError, "buckets value should not be nil"
        end
      end
    end
  end
end
