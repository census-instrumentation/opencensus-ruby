require "test_helper"

describe OpenCensus::Tags::TagMap do
  describe "create" do
    it "create tags map with defaults" do
      tag_map = OpenCensus::Tags::TagMap.new
      tag_map.length.must_equal 0
    end

    it "create tags map with tags key, values" do
      tag_map = OpenCensus::Tags::TagMap.new({ "frontend" => "mobile-1.0"})
      tag_map.length.must_equal 1
      tag_map["frontend"].must_equal "mobile-1.0"
    end

    it "create tag map with empty value" do
      tag_map = OpenCensus::Tags::TagMap.new({ "frontend" => ""})
      tag_map["frontend"].must_equal ""
    end

    describe "tag key validation" do
      it "raise error for empty key" do
        expect {
          raise OpenCensus::Tags::TagMap.new({ "" => "mobile-1.0"})
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if key length more then 255 chars" do
        key = "k" * 256
        expect {
          raise OpenCensus::Tags::TagMap.new({ key => "mobile-1.0"})
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if key contains non printable chars less then 32 ascii code" do
        key = "key#{[31].pack('c')}-test"
        expect {
          raise OpenCensus::Tags::TagMap.new({ key => "mobile-1.0"})
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if key contains non printable chars greater then 126 ascii code" do
        key = "key#{[127].pack('c')}-test"
        expect {
          raise OpenCensus::Tags::TagMap.new({ key => "mobile-1.0"})
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end
    end

    describe "tag value validation" do
      it "raise error if value length more then 255 chars" do
        value = "v" * 256
        expect {
          OpenCensus::Tags::TagMap.new({ "frontend" => value })
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if value contains non printable chars less then 32 ascii code" do
        value = "value#{[31].pack('c')}-test"
        expect {
          OpenCensus::Tags::TagMap.new({ "frontend" => value})
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if value contains non printable chars greater then 126 ascii code" do
        value = "value#{[127].pack('c')}-test"
        expect {
          OpenCensus::Tags::TagMap.new({ "frontend" => value })
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end
    end
  end

  describe "add tag to tag map" do
    it "set tag key value" do
      tag_map = OpenCensus::Tags::TagMap.new
      tag_map["frontend"] = "mobile-1.0"
      tag_map["frontend"].must_equal "mobile-1.0"
    end

    it "allow empty tag value" do
      tag_map = OpenCensus::Tags::TagMap.new
      tag_map["frontend"] = ""
      tag_map["frontend"].must_equal ""
    end

    describe "tag key validation" do
      let(:tag_map) { OpenCensus::Tags::TagMap.new }

      it "raise error for empty key" do
        expect {
          tag_map[""] = "mobile-1.0"
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if key length more then 255 chars" do
        key = "k" * 256
        expect {
          tag_map[key] = "mobile-1.0"
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if key contains non printable chars less then 32 ascii code" do
        key = "key#{[31].pack('c')}-test"
        expect {
          tag_map[key] = "mobile-1.0"
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if key contains non printable chars greater then 126 ascii code" do
        key = "key#{[127].pack('c')}-test"
        expect {
          tag_map[key] = "mobile-1.0"
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end
    end

    describe "tag value validation" do
      let(:tag_map) { OpenCensus::Tags::TagMap.new }

      it "raise error if value length more then 255 chars" do
        value = "v" * 256
        expect {
          tag_map["frontend"] = value
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if value contains non printable chars less then 32 ascii code" do
        value = "value#{[31].pack('c')}-test"
        expect {
          tag_map["frontend"] = value
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end

      it "raise error if value contains non printable chars greater then 126 ascii code" do
        value = "value#{[127].pack('c')}-test"
        expect {
          tag_map["frontend"] = value
        }.must_raise OpenCensus::Tags::TagMap::InvalidTagError
      end
    end
  end

  it "delete" do
    tag_map = OpenCensus::Tags::TagMap.new({ "frontend" => "mobile-1.0"})

    tag_map.delete "frontend"
    tag_map["frontend"].must_be_nil
    tag_map.length.must_equal 0
  end

  describe "binary formatter" do
    it "serialize tag map to binary format" do
      tag_map = OpenCensus::Tags::TagMap.new({
        "key1" => "val1",
        "key2" => "val2"
      })

      expected_binary = "\x00\x00\x04key1\x04val1\x00\x04key2\x04val2"
      tag_map.to_binary.must_equal expected_binary
    end

    it "deserialize binary format and create tag map" do
      binary = "\x00\x00\x04key1\x04val1\x00\x04key2\x04val2"

      tag_map = OpenCensus::Tags::TagMap.from_binary binary
      expected_value = {
        "key1" => "val1",
        "key2" => "val2"
      }
      tag_map.to_h.must_equal expected_value
    end
  end
end
