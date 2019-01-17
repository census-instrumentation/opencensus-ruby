require "test_helper"

describe OpenCensus::Tags do
  before{
    OpenCensus::Tags.unset_tag_map_context
  }

  it "can be set and unset tag map context" do
    tag_map = OpenCensus::Tags::TagMap.new({ "frontend" => "mobile-1.0"})
    OpenCensus::Tags.tag_map_context.must_be_nil
    OpenCensus::Tags.tag_map_context = tag_map
    OpenCensus::Tags.tag_map_context.must_equal tag_map
    OpenCensus::Tags.unset_tag_map_context
    OpenCensus::Tags.tag_map_context.must_be_nil
  end
end
