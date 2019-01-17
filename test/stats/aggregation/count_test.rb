require "test_helper"

describe OpenCensus::Stats::Aggregation::Count do
  describe "create_aggregation_data" do
    it "create count aggregation data instance with default value" do
      count_aggregation = OpenCensus::Stats::Aggregation::Count.new
      aggregation_data = count_aggregation.create_aggregation_data
      aggregation_data.must_be_kind_of OpenCensus::Stats::AggregationData::Count
      aggregation_data.value.must_equal 0
    end
  end
end
