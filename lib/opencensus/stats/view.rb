# frozen_string_literal: true


module OpenCensus
  module Stats
    class View
      attr_accessor :name, :measure, :aggregation, :columns, :description

      def initialize \
          name:,
          measure:,
          aggregation:,
          columns:,
          description: nil
        @name = name
        @measure = measure
        @aggregation = aggregation
        @columns = columns
        @description = description
        @time = Time.now
      end
    end
  end
end
