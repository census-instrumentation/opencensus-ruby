# frozen_string_literal: true


module OpenCensus
  module Stats
    class View
      attr_accessor :name, :measure, :aggregation, :tag_keys, :description

      def initialize \
          name:,
          measure:,
          aggregation:,
          tag_keys:,
          description: nil
        @name = name
        @measure = measure
        @aggregation = aggregation
        @tag_keys = tag_keys.sort
        @description = description
        @time = Time.now
      end
    end
  end
end
