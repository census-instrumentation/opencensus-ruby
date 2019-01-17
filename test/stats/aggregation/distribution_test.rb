require "test_helper"

describe OpenCensus::Stats::Aggregation::Distribution do
  let(:buckets) {
    [1,5,10]
  }

  describe "create" do
    it "create instance with buckets" do
      distribution_aggregation =
        OpenCensus::Stats::Aggregation::Distribution.new buckets
      distribution_aggregation.buckets.must_equal buckets
    end

    it "raise error if buckets value nil" do
      expect {
        OpenCensus::Stats::Aggregation::Distribution.new nil
      }.must_raise OpenCensus::Stats::Aggregation::Distribution::InvalidBucketsError
    end

    it "raise error if buckets are empty" do
      expect {
        OpenCensus::Stats::Aggregation::Distribution.new []
      }.must_raise OpenCensus::Stats::Aggregation::Distribution::InvalidBucketsError
    end

    it "raise error if any bucket value is nil " do
      expect {
        OpenCensus::Stats::Aggregation::Distribution.new [1, nil]
      }.must_raise OpenCensus::Stats::Aggregation::Distribution::InvalidBucketsError
    end

    it "reject bucket value if value is less then zero" do
      distribution_aggregation =
        OpenCensus::Stats::Aggregation::Distribution.new [1, -1, 10, -20]
      distribution_aggregation.buckets.must_equal [1, 10]
    end
  end

  describe "create_aggregation_data" do
    it "create distribution aggregation data instance with default values" do
      distribution_aggregation =
        OpenCensus::Stats::Aggregation::Distribution.new buckets
      aggregation_data = distribution_aggregation.create_aggregation_data
      aggregation_data.must_be_kind_of OpenCensus::Stats::AggregationData::Distribution
      aggregation_data.count.must_equal 0
      aggregation_data.sum.must_equal 0
      aggregation_data.max.must_equal(-Float::INFINITY)
      aggregation_data.min.must_equal Float::INFINITY
      aggregation_data.mean.must_equal 0
      aggregation_data.sum_of_squared_deviation.must_equal 0
      aggregation_data.buckets.must_equal buckets
      aggregation_data.bucket_counts.must_equal [0,0,0,0]
    end
  end
end
