require "test_helper"

describe OpenCensus::Stats::AggregationData::Count do
  it "create count aggregation data with default value" do
    aggregation_data = OpenCensus::Stats::AggregationData::Count.new
    aggregation_data.value.must_equal 0
  end

  describe "add" do
    it "add value" do
      aggregation_data = OpenCensus::Stats::AggregationData::Count.new

      time = Time.now
      aggregation_data.add time
      aggregation_data.value.must_equal 1
      aggregation_data.time.must_equal time
    end
  end
end
