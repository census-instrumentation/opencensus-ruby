require "test_helper"

describe OpenCensus::Tags::TagMap do
  let(:tag_key) { "frontend" }
  let(:tag_value){ "mobile-1.0.0" }
  let(:tag) {
    OpenCensus::Tags::Tag.new tag_key, tag_value
  }
  let(:tags){ [tag] }

  describe "create" do
    it "create tags map with defaults" do
      tag_map = OpenCensus::Tags::TagMap.new
      tag_map.length.must_equal 0
    end

    it "create tags map from tags key, values" do
      tag_map = OpenCensus::Tags::TagMap.new({ tag_key => tag_value })
      tag_map.length.must_equal 1
      tag_map[tag_key].value.must_equal tag_value
    end

    it "create tag map from tags array" do
      tag_map = OpenCensus::Tags::TagMap.new(tags)
      tag_map.length.must_equal 1
      tag_map[tag_key].value.must_equal tag_value
    end
  end

  describe "add tag to tag map" do
    it "set tag key value" do
      tag_map = OpenCensus::Tags::TagMap.new
      tag_map << OpenCensus::Tags::Tag.new(tag_key, tag_value)
      tag_map.length.must_equal 1
      tag_map[tag_key].value.must_equal tag_value
    end

    it "allow empty tag value" do
      tag_map = OpenCensus::Tags::TagMap.new
      tag_map << OpenCensus::Tags::Tag.new(tag_key, "")
      tag_map.length.must_equal 1
      tag_map[tag_key].value.must_equal ""
    end
  end

  it "delete tag" do
    tag_map = OpenCensus::Tags::TagMap.new [tag]

    tag_map.delete tag_key
    tag_map[tag_key].must_be_nil
    tag_map.length.must_equal 0
  end

  describe "binary formatter" do
    it "serialize tag map to binary format" do
      tag_map = OpenCensus::Tags::TagMap.new
      tag_map << OpenCensus::Tags::Tag.new("key1", "val1")
      tag_map << OpenCensus::Tags::Tag.new("key2", "val2")

      expected_binary = "\x00\x00\x04key1\x04val1\x00\x04key2\x04val2"
      tag_map.to_binary.must_equal expected_binary
    end

    it "deserialize binary format and create tag map" do
      binary = "\x00\x00\x04key1\x04val1\x00\x04key2\x04val2"

      tag_map = OpenCensus::Tags::TagMap.from_binary binary
      tag_map.length.must_equal 2
      tag_map["key1"].value.must_equal "val1"
      tag_map["key2"].value.must_equal "val2"
    end
  end
end
