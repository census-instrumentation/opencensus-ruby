require "test_helper"

describe OpenCensus::Stats::AggregationData::Sum do
  it "create sum aggregation data with default value" do
    aggregation_data = OpenCensus::Stats::AggregationData::Sum.new
    aggregation_data.value.must_equal 0
  end

  describe "add" do
    it "add value" do
      aggregation_data = OpenCensus::Stats::AggregationData::Sum.new

      time = Time.now
      aggregation_data.add 10, time
      aggregation_data.value.must_equal 10
      aggregation_data.time.must_equal time

      time = Time.now
      aggregation_data.add 15, time
      aggregation_data.value.must_equal 25
      aggregation_data.time.must_equal time
    end
  end
end
