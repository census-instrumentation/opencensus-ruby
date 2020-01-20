require "test_helper"

describe OpenCensus::Stats do
  let(:tags) {
    [
      OpenCensus::Tags::Tag.new("tag1", "value1"),
      OpenCensus::Tags::Tag.new("tag2", "value2")
    ]
  }

  describe "stats context" do
    before {
      OpenCensus::Stats.unset_recorder_context
    }

    it "can be set and unset stats context" do
      stats_recorder = OpenCensus::Stats::Recorder.new

      OpenCensus::Stats.recorder_context.must_be_nil
      OpenCensus::Stats.recorder_context = stats_recorder
      OpenCensus::Stats.recorder_context.must_equal stats_recorder
      OpenCensus::Stats.unset_recorder_context
      OpenCensus::Stats.recorder_context.must_be_nil
    end

    it "create stats recorder and set into local thread" do
      stats_recorder = OpenCensus::Stats.ensure_recorder
      stats_recorder.must_be_kind_of OpenCensus::Stats::Recorder
      OpenCensus::Stats.ensure_recorder.must_equal stats_recorder
    end
  end

  describe "measure" do
    before {
      OpenCensus::Stats::MeasureRegistry.clear
    }

    it "create int measure" do
      measure = OpenCensus::Stats.create_measure_int(
        name: "Latency",
        unit: "ms",
        description: "Test description"
      )

      measure.must_be_kind_of OpenCensus::Stats::Measure
      measure.int64?.must_equal true
      measure.name.must_equal "Latency"
      measure.unit.must_equal "ms"
      measure.description.must_equal "Test description"
      OpenCensus::Stats::MeasureRegistry.get(measure.name).must_equal measure
    end

    it "create double type measure" do
      measure = OpenCensus::Stats.create_measure_double(
        name: "Storage",
        unit: "kb",
        description: "Test description"
      )
      measure.must_be_kind_of OpenCensus::Stats::Measure
      measure.double?.must_equal true
      measure.name.must_equal "Storage"
      measure.unit.must_equal "kb"
      measure.description.must_equal "Test description"
      OpenCensus::Stats::MeasureRegistry.get(measure.name).must_equal measure
    end

    it "get list of registered measure" do
      measure = OpenCensus::Stats.create_measure_double(
        name: "Storage-1",
        unit: "kb",
        description: "Test description"
      )
      OpenCensus::Stats.registered_measures.first.must_equal measure
    end

    it "prevents dublicate measure registration" do
      measure_name = "Storage-2"
      measure = OpenCensus::Stats.create_measure_double(
        name: measure_name,
        unit: "kb",
        description: "Test description"
      )

      OpenCensus::Stats.create_measure_double(
        name: measure_name,
        unit: "kb",
        description: "Test description"
      ).must_be_nil

      OpenCensus::Stats.registered_measures.length.must_equal 1
      OpenCensus::Stats::MeasureRegistry.get(measure_name).must_equal measure
    end
  end

  describe "create_measurement" do
    before {
      OpenCensus::Stats::MeasureRegistry.clear
    }
    it "create measurement" do
      measure = OpenCensus::Stats.create_measure_int(
        name: "latency",
        unit: "ms",
        description: "Test description"
      )

      measurement = OpenCensus::Stats.create_measurement(
        name: "latency",
        value: 10,
        tags: tags
      )
      measurement.measure.must_equal measure
      measurement.value.must_equal 10
    end

    it "raise an error if measure not found in registry" do
      expect {
          OpenCensus::Stats.create_measurement(
            name: "latency-#{Time.now.to_i}",
            value: 10,
            tags: tags
          )
      }.must_raise ArgumentError
    end
  end

  describe "aggregation" do
    it "create count aggregation" do
      aggregation = OpenCensus::Stats.create_count_aggregation
      aggregation.must_be_kind_of OpenCensus::Stats::Aggregation::Count
    end

    it "create sum aggregation" do
      aggregation = OpenCensus::Stats.create_sum_aggregation
      aggregation.must_be_kind_of OpenCensus::Stats::Aggregation::Sum
    end

    it "create last value aggregation" do
      aggregation = OpenCensus::Stats.create_last_value_aggregation
      aggregation.must_be_kind_of OpenCensus::Stats::Aggregation::LastValue
    end

    it "create distribution aggregation" do
      aggregation = OpenCensus::Stats.create_distribution_aggregation [1, 10]
      aggregation.must_be_kind_of OpenCensus::Stats::Aggregation::Distribution
      aggregation.buckets.must_equal [1, 10]
    end
  end

  describe "create_and_register_view" do
    let(:measure){
      OpenCensus::Stats.create_measure_double(
        name: "Storage",
        unit: "kb",
        description: "Test description"
      )
    }
    let(:aggregation){ OpenCensus::Stats.create_sum_aggregation }

    it "create and register view" do
      view = OpenCensus::Stats.create_and_register_view(
        name: "test.view",
        measure: measure,
        aggregation: aggregation,
        description: "Test description",
        columns: ["frontend"]
      )

      view.must_be_kind_of OpenCensus::Stats::View
      view.name.must_equal "test.view"
      view.measure.must_equal measure
      view.aggregation.must_equal aggregation
      view.columns.must_equal ["frontend"]
      OpenCensus::Stats.ensure_recorder.views[view.name].must_equal view
    end
  end
end
