require "test_helper"

describe OpenCensus::Stats::AggregationData do
  describe "sum aggregation" do
    it "create and populates default value" do
      aggr_data = OpenCensus::Stats::AggregationData.new :sum
      aggr_data.type.must_equal :sum
      aggr_data.data.must_equal 0
    end

    it "add value" do
      aggr_data = OpenCensus::Stats::AggregationData.new :sum
      aggr_data.add 10
      aggr_data.data.must_equal 10

      aggr_data.add 5
      aggr_data.data.must_equal 15
    end
  end

  describe "count aggregation" do
    it "create and populates default value" do
      aggr_data = OpenCensus::Stats::AggregationData.new :count
      aggr_data.type.must_equal :count
      aggr_data.data.must_equal 0
    end

    it "add value" do
      aggr_data = OpenCensus::Stats::AggregationData.new :count
      aggr_data.add 10
      aggr_data.data.must_equal 1

      aggr_data.add 20
      aggr_data.data.must_equal 2
    end
  end

  describe "last_value aggregation" do
    it "create and populates default value" do
      aggr_data = OpenCensus::Stats::AggregationData.new :last_value
      aggr_data.type.must_equal :last_value
      aggr_data.data.must_be_nil
    end

    it "add value" do
      aggr_data = OpenCensus::Stats::AggregationData.new :last_value
      aggr_data.add 10
      aggr_data.data.must_equal 10

      aggr_data.add 20
      aggr_data.data.must_equal 20
    end
  end

  describe "distribution aggregation" do
    let(:buckets) { [2, 4, 6]}
    it "create and populates default value" do
      aggr_data = OpenCensus::Stats::AggregationData.new :distribution, buckets: buckets
      aggr_data.type.must_equal :distribution
      aggr_data.data[:bucket_counts].length.must_equal(buckets.length + 1)

      expected_data = {
        count: 0,
        sum: 0,
        max: -Float::INFINITY,
        min: Float::INFINITY,
        mean: 0,
        sum_of_squared_deviation: 0,
        buckets: buckets,
        bucket_counts: [0, 0, 0, 0]
      }
      aggr_data.data.must_equal expected_data
    end

    it "add values" do
      aggr_data = OpenCensus::Stats::AggregationData.new :distribution, buckets: buckets

      values = [1, 3, 5, 10, 4]
      values.each { |v| aggr_data.add v }

      mean = ( values.sum.to_f / values.length )
      expected_data = {
        count: values.length,
        sum: values.sum,
        max: values.max,
        min: values.min,
        mean: mean,
        sum_of_squared_deviation: values.map { |v| (v - mean)**2 }.sum,
        buckets: buckets,
        bucket_counts: [1, 1, 2, 1]
      }

      aggr_data.data.must_equal expected_data
    end
  end
end
