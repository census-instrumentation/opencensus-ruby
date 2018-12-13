require "test_helper"

describe OpenCensus::Tags::Formatters::Binary do
  let(:formatter) { OpenCensus::Tags::Formatters::Binary.new }

  describe "serialize" do
    it "return serialize tag map binary data" do
      tag_map = OpenCensus::Tags::TagMap.new({
        "key1" => "val1",
        "key2" => "val2",
        "key3" => "val3",
        "key4" => "val4",
      })

      binary = formatter.serialize(tag_map)
      expected_binary = "\x00\x00\x04key1\x04val1\x00\x04key2\x04val2\x00\x04key3\x04val3\x00\x04key4\x04val4"
      binary.must_equal expected_binary
    end

    it "return nil if tag map serialize data size more then 8192 bytes" do
      tag_map = OpenCensus::Tags::TagMap.new

      500.times do |i|
        tag_map["key#{i}"] = "value#{i}"
      end

      binary = formatter.serialize(tag_map)
      binary.must_be_nil
    end
  end

  describe "deserialize" do
    it "deserialize binary data" do
      binary = "\x00\x00\x04key1\x04val1\x00\x04key2\x04val2\x00\x04key3\x04val3\x00\x04key4\x04val4"

      tag_map = formatter.deserialize binary
      tag_map.length.must_equal 4

      expected_tag_map_values = {
        "key1" => "val1",
        "key2" => "val2",
        "key3" => "val3",
        "key4" => "val4",
      }
      tag_map.to_h.must_equal expected_tag_map_values
    end

    it "returns empty tag map for empty string" do
      tag_map = formatter.deserialize ""
      tag_map.length.must_equal 0
    end

    it "returns empty tag map for nil" do
      tag_map = formatter.deserialize nil
      tag_map.length.must_equal 0
    end

    it "raise an error for invalid verion id" do
      binary = "\x01\x00\x04key1\x04val1"

      error = expect {
        formatter.deserialize binary
      }.must_raise OpenCensus::Tags::Formatters::Binary::BinaryFormatterError
      error.message.must_match /invalid version id/i
    end

    it "stop parsing subsequent tags if found invalid field tag id" do
      binary = "\x00\x00\x04key1\x04val1\x01\x04key2\x04val2\x00\x04key3\x04val3"

      tag_map = formatter.deserialize binary
      tag_map.to_h.must_equal({ "key1" => "val1" })
    end
  end
end
