require "test_helper"

describe OpenCensus::Stats::Measurement do
  let(:tag_key) { "key1" }
  let(:tag_value) { "val1" }
  let(:tag){
    OpenCensus::Tags::Tag.new tag_key, tag_value
  }
  let(:tags) {
    OpenCensus::Tags::TagMap.new [tag]
  }

  describe "create" do
    it "int64 type measure" do
      measure = OpenCensus::Stats::Measure.new(
        name: "latency",
        unit: "ms",
        type: OpenCensus::Stats::Measure::INT64_TYPE,
        description: "latency desc"
      )

      measure.name.must_equal "latency"
      measure.unit.must_equal "ms"
      measure.type.must_equal OpenCensus::Stats::Measure::INT64_TYPE
      measure.description.must_equal "latency desc"
      measure.int64?.must_equal true
      measure.double?.must_equal false
    end

    it "double type measure" do
      measure = OpenCensus::Stats::Measure.new(
        name: "storage",
        unit: "kb",
        type: OpenCensus::Stats::Measure::DOUBLE_TYPE,
        description: "storage desc"
      )

      measure.name.must_equal "storage"
      measure.unit.must_equal "kb"
      measure.type.must_equal OpenCensus::Stats::Measure::DOUBLE_TYPE
      measure.description.must_equal "storage desc"
      measure.double?.must_equal true
      measure.int64?.must_equal false
    end
  end

  it "create measurement instance" do
    measure = OpenCensus::Stats::Measure.new(
      name: "storage",
      unit: "kb",
      type: OpenCensus::Stats::Measure::DOUBLE_TYPE,
      description: "storage desc"
    )

    measurement = measure.create_measurement value: 10.10, tags: tags
    measurement.value.must_equal 10.10
    measurement.measure.must_equal measure
    measurement.tags.must_be_kind_of OpenCensus::Tags::TagMap
    measurement.tags[tag_key].value.must_equal tag_value
  end
end
