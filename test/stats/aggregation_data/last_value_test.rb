require "test_helper"

describe OpenCensus::Stats::AggregationData::LastValue do
  it "create count aggregation data with default value" do
    aggregation_data = OpenCensus::Stats::AggregationData::LastValue.new
    aggregation_data.value.must_be_nil
  end

  describe "add" do
    it "add value" do
      aggregation_data = OpenCensus::Stats::AggregationData::LastValue.new

      time = Time.now
      aggregation_data.add 1, time
      aggregation_data.value.must_equal 1
      aggregation_data.time.must_equal time

      time = Time.now
      aggregation_data.add 10, time
      aggregation_data.value.must_equal 10
      aggregation_data.time.must_equal time
    end
  end
end
