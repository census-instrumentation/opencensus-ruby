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
    aggregation_data.exemplars.must_be_empty
  end

  describe "add" do
    it "add value without attachments" do
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
      aggregation_data.exemplars.must_be_empty
    end

    it "add value with attachments and record value to exampler" do
      buckets = [1, 3, 10]
      aggregation_data = OpenCensus::Stats::AggregationData::Distribution.new(
        buckets
      )

      attachments = { "trace_id" => "1111-1111" }
      values = [1, 5, 10, 2]
      time = Time.now
      values.each do |value|
        aggregation_data.add value, time, attachments: attachments
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

      expected_bucket_counts = [0, 2, 1, 1]
      aggregation_data.bucket_counts.must_equal expected_bucket_counts

      expected_examples_values = {
        0 => nil,
        1 => 2,
        2 => 5,
        3 => 10
      }

      expected_examples_values.each do |k, v|
        if v.nil?
          aggregation_data.exemplars[k].must_be_nil
        else
          aggregation_data.exemplars[k].value.must_equal v
          aggregation_data.exemplars[k].time.must_equal time
          aggregation_data.exemplars[k].attachments.must_equal attachments
        end
      end
    end
  end
end
