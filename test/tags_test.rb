require "test_helper"

describe OpenCensus::Tags do
  before{
    OpenCensus::Tags.unset_tags_context
  }
  it "can be set and unset tags context" do
    tag_map = OpenCensus::Tags::TagMap.new({ "frontend" => "mobile-1.0"})
    OpenCensus::Tags.tags_context.must_be_nil
    OpenCensus::Tags.tags_context = tag_map
    OpenCensus::Tags.tags_context.must_equal tag_map
    OpenCensus::Tags.unset_tags_context
    OpenCensus::Tags.tags_context.must_be_nil
  end
end
