require "test_helper"

describe OpenCensus::Stats::Measurement do
  let(:tag_key) { "key1" }
  let(:tag_value) { "val1" }
  let(:tag){
    OpenCensus::Tags::Tag.new tag_key, tag_value
  }
  let(:measure){
    OpenCensus::Stats::Measure.new(
      name: "storage",
      unit: "kb",
      type: OpenCensus::Stats::Measure::DOUBLE_TYPE,
      description: "storage desc"
    )
  }

  describe "create" do
    it "create using tag map instance" do
      tags = OpenCensus::Tags::TagMap.new [tag]

      measurement = OpenCensus::Stats::Measurement.new(
        measure: measure,
        value: 10.10,
        tags: tags
      )
      measurement.measure.must_equal measure
      measurement.value.must_equal 10.10
      measurement.tags.must_be_kind_of OpenCensus::Tags::TagMap
      measurement.tags[tag_key].value.must_equal tag_value
      measurement.time.must_be_kind_of Time
    end

    it "create using hash" do
      tags = { tag_key => tag_value }
      measurement = OpenCensus::Stats::Measurement.new(
        measure: measure,
        value: 10.10,
        tags: tags
      )
      measurement.measure.must_equal measure
      measurement.value.must_equal 10.10
      measurement.tags.must_be_kind_of OpenCensus::Tags::TagMap
      measurement.tags[tag_key].value.must_equal tag_value
      measurement.time.must_be_kind_of Time
    end
  end
end
