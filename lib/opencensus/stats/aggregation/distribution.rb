# frozen_string_literal: true


module OpenCensus
  module Stats
    module Aggregation
      # Distribution aggregation type
      class Distribution
        # Invalid bucket types.
        class InvalidBucketsError < StandardError; end

        # @return [Array<Integer>,Array<Float>] Bucket boundries.
        attr_reader :buckets

        # @private
        # @param [Array<Integer>,Array<Float>,] buckets Buckets boundries
        # for distribution
        # aggregation.
        # @raise [InvalidBucketsError] If any bucket value is nil.
        def initialize buckets
          if buckets.nil? || buckets.empty?
            raise InvalidBucketsError, "buckets should not be nil or empty"
          end

          if buckets.any?(&:nil?)
            raise InvalidBucketsError, "buckets value should not be nil"
          end

          @buckets = buckets.reject { |v| v < 0 }
        end

        # Create new aggregation data container to store distribution values.
        # values.
        # @return [AggregationData::Distribution]
        def create_aggregation_data
          AggregationData::Distribution.new @buckets
        end
      end
    end
  end
end
