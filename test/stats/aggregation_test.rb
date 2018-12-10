require "test_helper"

describe OpenCensus::Stats::Aggregation do
  it "create instance and populates properties" do
    aggregation = OpenCensus::Stats::Aggregation.new :distribution, buckets: [1,2,3]

    aggregation.type.must_equal :distribution
    aggregation.buckets.must_equal [1,2,3]
  end

  describe "aggregation data" do
    it "create sum aggregation data" do
      aggregation = OpenCensus::Stats::Aggregation.new :sum

      aggr_data = aggregation.new_aggregation_data
      aggr_data.must_be_instance_of OpenCensus::Stats::AggregationData
      aggr_data.type.must_equal :sum
      aggr_data.data.must_equal 0
    end

    it "create count aggregation data" do
      aggregation = OpenCensus::Stats::Aggregation.new :count

      aggr_data = aggregation.new_aggregation_data
      aggr_data.must_be_instance_of OpenCensus::Stats::AggregationData
      aggr_data.type.must_equal :count
      aggr_data.data.must_equal 0
    end

    it "create last value aggregation data" do
      aggregation = OpenCensus::Stats::Aggregation.new :last_value

      aggr_data = aggregation.new_aggregation_data
      aggr_data.must_be_instance_of OpenCensus::Stats::AggregationData
      aggr_data.type.must_equal :last_value
      aggr_data.data.must_be_nil
    end

    it "create distribution aggregation data" do
      aggregation = OpenCensus::Stats::Aggregation.new :distribution, buckets: [1, 5, 10]

      expected_data = {
        count: 0,
        sum: 0,
        max: -Float::INFINITY,
        min: Float::INFINITY,
        mean: 0,
        sum_of_squared_deviation: 0,
        buckets: [1, 5, 10],
        bucket_counts: [0, 0, 0, 0]
      }

      aggr_data = aggregation.new_aggregation_data
      aggr_data.must_be_instance_of OpenCensus::Stats::AggregationData
      aggr_data.type.must_equal :distribution
      aggr_data.data.must_equal expected_data
    end

    describe "distribution bucket validations" do
      it "raise exception if buckets is nil" do
        expect {
          OpenCensus::Stats::Aggregation.new :distribution, buckets: nil
        }.must_raise OpenCensus::Stats::Aggregation::InvaliedBucketsError
      end

      it "raise exception if nil buckets values" do
        expect {
          OpenCensus::Stats::Aggregation.new :distribution, buckets: [1, nil, 10]
        }.must_raise OpenCensus::Stats::Aggregation::InvaliedBucketsError
      end
    end
  end
end
