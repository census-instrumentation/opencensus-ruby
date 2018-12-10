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
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if key length more then 255 chars" do
        key = "k" * 256
        expect {
          raise OpenCensus::Tags::TagMap.new({ key => "mobile-1.0"})
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if key contains non printable chars less then 32 ascii code" do
        key = "key#{[31].pack('c')}-test"
        expect {
          raise OpenCensus::Tags::TagMap.new({ key => "mobile-1.0"})
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if key contains non printable chars greater then 126 ascii code" do
        key = "key#{[127].pack('c')}-test"
        expect {
          raise OpenCensus::Tags::TagMap.new({ key => "mobile-1.0"})
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end
    end

    describe "tag value validation" do
      it "raise error if value length more then 255 chars" do
        value = "v" * 256
        expect {
          OpenCensus::Tags::TagMap.new({ "frontend" => value })
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if value contains non printable chars less then 32 ascii code" do
        value = "value#{[31].pack('c')}-test"
        expect {
          OpenCensus::Tags::TagMap.new({ "frontend" => value})
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if value contains non printable chars greater then 126 ascii code" do
        value = "value#{[127].pack('c')}-test"
        expect {
          OpenCensus::Tags::TagMap.new({ "frontend" => value })
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
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
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if key length more then 255 chars" do
        key = "k" * 256
        expect {
          tag_map[key] = "mobile-1.0"
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if key contains non printable chars less then 32 ascii code" do
        key = "key#{[31].pack('c')}-test"
        expect {
          tag_map[key] = "mobile-1.0"
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if key contains non printable chars greater then 126 ascii code" do
        key = "key#{[127].pack('c')}-test"
        expect {
          tag_map[key] = "mobile-1.0"
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end
    end

    describe "tag value validation" do
      let(:tag_map) { OpenCensus::Tags::TagMap.new }

      it "raise error if value length more then 255 chars" do
        value = "v" * 256
        expect {
          tag_map["frontend"] = value
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if value contains non printable chars less then 32 ascii code" do
        value = "value#{[31].pack('c')}-test"
        expect {
          tag_map["frontend"] = value
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end

      it "raise error if value contains non printable chars greater then 126 ascii code" do
        value = "value#{[127].pack('c')}-test"
        expect {
          tag_map["frontend"] = value
        }.must_raise OpenCensus::Tags::TagMap::InvaliedTagError
      end
    end
  end

  it "delete" do
    tag_map = OpenCensus::Tags::TagMap.new({ "frontend" => "mobile-1.0"})

    tag_map.delete "frontend"
    tag_map["frontend"].must_be_nil
    tag_map.length.must_equal 0
  end

end
