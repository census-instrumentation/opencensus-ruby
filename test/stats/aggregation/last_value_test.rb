require "test_helper"

describe OpenCensus::Stats::Aggregation::LastValue do
  describe "create_aggregation_data" do
    it "create last value aggregation data instance with default value" do
      last_value_aggregation = OpenCensus::Stats::Aggregation::LastValue.new
      aggregation_data = last_value_aggregation.create_aggregation_data
      aggregation_data.must_be_kind_of OpenCensus::Stats::AggregationData::LastValue
      aggregation_data.value.must_be_nil
    end
  end
end
