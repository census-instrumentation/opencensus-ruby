require "test_helper"

describe OpenCensus::Stats::Aggregation::Sum do
  describe "create_aggregation_data" do
    it "create sum aggregation data instance with default value" do
      sum_aggregation = OpenCensus::Stats::Aggregation::Sum.new
      aggregation_data = sum_aggregation.create_aggregation_data
      aggregation_data.must_be_kind_of OpenCensus::Stats::AggregationData::Sum
      aggregation_data.value.must_equal 0
    end
  end
end
