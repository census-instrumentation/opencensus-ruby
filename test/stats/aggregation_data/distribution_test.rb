require "test_helper"

describe OpenCensus::Stats::AggregationData::Distribution do
  let(:buckets) {
    [2,4,6]
  }

  it "create distribution aggregation data instance with default values" do
    aggregation_data = OpenCensus::Stats::AggregationData::Distribution.new(
      buckets
    )
    aggregation_data.count.must_equal 0
    aggregation_data.sum.must_equal 0
    aggregation_data.max.must_equal(-Float::INFINITY)
    aggregation_data.min.must_equal Float::INFINITY
    aggregation_data.mean.must_equal 0
    aggregation_data.sum_of_squared_deviation.must_equal 0
    aggregation_data.buckets.must_equal buckets
    aggregation_data.bucket_counts.must_equal [0,0,0,0]
  end

  describe "add" do
    it "add value" do
      aggregation_data = OpenCensus::Stats::AggregationData::Distribution.new(
        buckets
      )

      values = [1, 3, 5, 10, 4]
      time = nil
      values.each do |value|
        time = Time.now
        aggregation_data.add value, time
      end

      aggregation_data.time.must_equal time
      aggregation_data.count.must_equal values.length
      aggregation_data.sum.must_equal values.inject(:+)
      aggregation_data.max.must_equal values.max
      aggregation_data.min.must_equal values.min

      mean = ( values.inject(:+).to_f / values.length )
      aggregation_data.mean.must_equal mean

      sum_of_squared_deviation = values.map { |v| (v - mean)**2 }.inject(:+)
      aggregation_data.sum_of_squared_deviation.must_equal sum_of_squared_deviation
      aggregation_data.buckets.must_equal buckets
      aggregation_data.bucket_counts.must_equal [1, 1, 2, 1]
    end
  end
end
