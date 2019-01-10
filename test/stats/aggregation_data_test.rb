require "test_helper"

describe OpenCensus::Stats::AggregationData do
  describe "add" do
    it "add value to sum aggregation data" do
      aggregation_data = OpenCensus::Stats::AggregationData::Sum.new
      OpenCensus::Stats::AggregationData.add aggregation_data, 10, Time.now
      aggregation_data.value.must_equal 10
    end

    it "add value to count aggregation data" do
      aggregation_data = OpenCensus::Stats::AggregationData::Count.new
      OpenCensus::Stats::AggregationData.add aggregation_data, nil, Time.now
      aggregation_data.value.must_equal 1
    end

    it "add value to last value aggregation data" do
      aggregation_data = OpenCensus::Stats::AggregationData::LastValue.new
      OpenCensus::Stats::AggregationData.add aggregation_data, 200, Time.now
      aggregation_data.value.must_equal 200
    end

    it "add value to distibution aggregation data" do
      buckets = [1,5,10]
      aggregation_data = OpenCensus::Stats::AggregationData::Distribution.new(
        buckets
      )
      values = [3, 5, 10]
      values.each do |value|
        OpenCensus::Stats::AggregationData.add aggregation_data, value, Time.now
      end

      aggregation_data.count.must_equal values.length
      aggregation_data.sum.must_equal values.inject(:+)
      aggregation_data.max.must_equal values.max
      aggregation_data.min.must_equal values.min

      mean = ( values.inject(:+).to_f / values.length )
      aggregation_data.mean.must_equal mean

      sum_of_squared_deviation = values.map { |v| (v - mean)**2 }.inject(:+)
      aggregation_data.sum_of_squared_deviation.must_equal sum_of_squared_deviation
      aggregation_data.buckets.must_equal buckets
      aggregation_data.bucket_counts.must_equal [0, 1, 1, 1]
    end
  end
end
