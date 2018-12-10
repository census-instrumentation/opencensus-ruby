require "test_helper"

describe OpenCensus::Stats::Measurement do
  describe "create" do
    it "int type measure" do
      measure = OpenCensus::Stats::Measure.new(
        name: "latency",
        unit: "ms",
        type: :int,
        description: "latency desc"
      )

      measure.name.must_equal "latency"
      measure.unit.must_equal "ms"
      measure.type.must_equal :int
      measure.description.must_equal "latency desc"
      measure.int?.must_equal true
      measure.float?.must_equal false
    end

    it "float type measure" do
      measure = OpenCensus::Stats::Measure.new(
        name: "storage",
        unit: "kb",
        type: :float,
        description: "storage desc"
      )

      measure.name.must_equal "storage"
      measure.unit.must_equal "kb"
      measure.type.must_equal :float
      measure.description.must_equal "storage desc"
      measure.float?.must_equal true
      measure.int?.must_equal false
    end
  end

  it "create measurement instance" do
    measure = OpenCensus::Stats::Measure.new(
      name: "storage",
      unit: "kb",
      type: :float,
      description: "storage desc"
    )

    measurement = measure.measurement 10.0
    measurement.value.must_equal 10.0
    measurement.measure.must_equal measure
  end
end
