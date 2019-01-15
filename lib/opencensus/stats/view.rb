# frozen_string_literal: true


module OpenCensus
  module Stats
    # View
    #
    # A View specifies an aggregation and a set of tag keys.
    # The aggregation will be broken down by the unique set of matching tag
    # values for each measure.
    class View
      # @return [String] Name of the view
      attr_reader :name

      # @return [Measure] Associated measure definition instance.
      attr_reader :measure

      # @return [Aggregation] Associated aggregation definition instance.
      attr_reader :aggregation

      # Columns (a.k.a Tag Keys) to match with the
      # associated Measure. Measure will be recorded in a "greedy" way.
      # That is, every view aggregates every measure.
      # This is similar to doing a GROUPBY on view columns. Columns must be
      # unique.
      # @return [Array<String>]
      attr_reader :columns

      # @return [String] Detailed description
      attr_reader :description

      # @return [Time] View creation time.
      attr_reader :time

      # Create instance of the view
      #
      # @param [String] name
      # @param [Measure] measure
      # @param [Aggregation] aggregation
      # @param [Array<String>] columns
      # @param [String] description
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
        @time = Time.now.utc
      end
    end
  end
end
