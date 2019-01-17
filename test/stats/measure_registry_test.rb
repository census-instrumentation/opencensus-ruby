require "test_helper"

describe OpenCensus::Stats::MeasureRegistry do
  before{
    OpenCensus::Stats::MeasureRegistry.clear
  }

  describe "register" do
    it "register measure" do
      OpenCensus::Stats::MeasureRegistry.register(
        name: "latency",
        unit: "ms",
        type: OpenCensus::Stats::Measure::INT64_TYPE,
        description: "latency desc"
      ).must_be_kind_of OpenCensus::Stats::Measure

      measure = OpenCensus::Stats::MeasureRegistry.get "latency"
      measure.must_be_kind_of OpenCensus::Stats::Measure
      measure.name.must_equal "latency"
      measure.unit.must_equal "ms"
      measure.type.must_equal OpenCensus::Stats::Measure::INT64_TYPE
      measure.description.must_equal "latency desc"
      measure.int64?.must_equal true
    end

    it "won't register dublicate measure" do
      measure1 = OpenCensus::Stats::MeasureRegistry.register(
        name: "latency-1",
        unit: "ms",
        type: OpenCensus::Stats::Measure::INT64_TYPE,
        description: "latency desc"
      )
      measure1.must_be_kind_of OpenCensus::Stats::Measure

      OpenCensus::Stats::MeasureRegistry.register(
        name: "latency-1",
        unit: "ms",
        type: OpenCensus::Stats::Measure::INT64_TYPE,
        description: "latency desc"
      ).must_be_nil

      OpenCensus::Stats::MeasureRegistry.measures.length.must_equal 1
      OpenCensus::Stats::MeasureRegistry.get("latency-1").must_equal measure1
    end
  end

  describe "get" do
    it "get measure" do
      measure = OpenCensus::Stats::MeasureRegistry.register(
        name: "latency",
        unit: "ms",
        type: OpenCensus::Stats::Measure::INT64_TYPE,
        description: "latency desc"
      )

      OpenCensus::Stats::MeasureRegistry.get("latency").must_equal measure
    end
  end

  describe "list" do
    it "list all measures" do
      OpenCensus::Stats::MeasureRegistry.register(
        name: "latency",
        unit: "ms",
        type: OpenCensus::Stats::Measure::INT64_TYPE,
        description: "latency desc"
      )

      OpenCensus::Stats::MeasureRegistry.measures.length.must_equal 1
    end
  end

  describe "unregister" do
    it "unregister measure by name" do
      OpenCensus::Stats::MeasureRegistry.register(
        name: "latency",
        unit: "ms",
        type: OpenCensus::Stats::Measure::INT64_TYPE,
        description: "latency desc"
      )

      OpenCensus::Stats::MeasureRegistry.measures.length.must_equal 1
      OpenCensus::Stats::MeasureRegistry.unregister "latency"
      OpenCensus::Stats::MeasureRegistry.measures.length.must_equal 0
    end
  end

  describe "clear" do
    it "remove all measures from registry" do
      OpenCensus::Stats::MeasureRegistry.register(
        name: "latency",
        unit: "ms",
        type: OpenCensus::Stats::Measure::INT64_TYPE,
        description: "latency desc"
      )

      OpenCensus::Stats::MeasureRegistry.measures.length.must_equal 1
      OpenCensus::Stats::MeasureRegistry.clear
      OpenCensus::Stats::MeasureRegistry.measures.length.must_equal 0
    end
  end
end
