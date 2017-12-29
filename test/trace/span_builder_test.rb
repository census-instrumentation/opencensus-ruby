# Copyright 2017 OpenCensus Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "test_helper"

describe OpenCensus::Trace::SpanBuilder do
  let(:span_context) { OpenCensus::Trace::SpanContext.create_root }
  let(:span_builder) { span_context.start_span "span name" }
  before { span_builder.finish! }

  describe "trace_id" do
    it "should be generated" do
      span_builder.trace_id.wont_be_nil
    end
  end

  describe "span_id" do
    it "should be generated" do
      span_builder.span_id.wont_be_nil
    end
  end

  describe "parent_span_id" do
    it "should be empty for root span" do
      span_builder.parent_span_id.must_be_empty
    end

    it "should be set for nested span" do
      span_builder2 = span_builder.context.start_span "inner span"
      span_builder2.parent_span_id.wont_be_nil
    end
  end

  describe "start!" do
    it "should not allow you to start more than once" do
      err = -> { span_builder.start! }.must_raise RuntimeError
      err.message.must_match "already started"
    end
  end

  describe "end!" do
    it "should not allow you to start more than once" do
      err = -> { span_builder.finish! }.must_raise RuntimeError
      err.message.must_match "already finished"
    end
  end

  describe "put_attribute" do
    let(:ret) { span_builder.put_attribute "foo", "bar" }

    it "should be chainable" do
      ret.must_be_instance_of OpenCensus::Trace::SpanBuilder
      ret.must_be_same_as span_builder
    end

    it "should be captured" do
      span = ret.to_span
      span.attributes["foo"].value.must_equal "bar"
    end
  end

  describe "put_annotation" do
    let(:ret) { span_builder.put_annotation "some message" }

    it "should be chainable" do
      ret.must_be_instance_of OpenCensus::Trace::SpanBuilder
      ret.must_be_same_as span_builder
    end

    it "should be captured" do
      span = ret.to_span
      span.time_events.size.must_equal 1
      annotation = span.time_events.first
      annotation.must_be_instance_of OpenCensus::Trace::Annotation
      annotation.description.value.must_equal "some message"
    end
  end

  describe "put_message_event" do
    let(:ret) do
      span_builder.put_message_event(
        OpenCensus::Trace::SpanBuilder::SENT,
        1,
        100
      )
    end

    it "should be chainable" do
      ret.must_be_instance_of OpenCensus::Trace::SpanBuilder
      ret.must_be_same_as span_builder
    end

    it "should be captured" do
      span = ret.to_span
      span.time_events.size.must_equal 1
      message_event = span.time_events.first
      message_event.must_be_instance_of OpenCensus::Trace::MessageEvent
      message_event.type.must_equal OpenCensus::Trace::MessageEvent::SENT
    end
  end

  describe "put_link" do
    let(:ret) do
      span_builder.put_link(
        "trace id",
        "span id",
        OpenCensus::Trace::SpanBuilder::CHILD_LINKED_SPAN
      )
    end

    it "should be chainable" do
      ret.must_be_instance_of OpenCensus::Trace::SpanBuilder
      ret.must_be_same_as span_builder
    end

    it "should be captured" do
      span = ret.to_span
      span.links.size.must_equal 1
      link = span.links.first
      link.must_be_instance_of OpenCensus::Trace::Link
      link.trace_id.must_equal "trace id"
      link.span_id.must_equal "span id"
      link.type.must_equal OpenCensus::Trace::Link::CHILD_LINKED_SPAN
    end
  end

  describe "set_status" do
    let(:ret) { span_builder.set_status(200, "OK") }

    it "should be chainable" do
      ret.must_be_instance_of OpenCensus::Trace::SpanBuilder
      ret.must_be_same_as span_builder
    end

    it "should be captured" do
      span = ret.to_span
      span.status.wont_be_nil
      status = span.status
      status.code.must_equal 200
      status.message.must_equal "OK"
    end
  end
end

describe OpenCensus::Trace::SpanBuilder::PieceBuilder do
  let(:builder_with_small_maxes) {
    OpenCensus::Trace::SpanBuilder::PieceBuilder.new \
      max_attributes: 3,
      max_stack_frames: 3,
      max_annotations: 3,
      max_message_events: 3,
      max_links: 3,
      max_string_length: 10
  }
  let(:builder_with_no_maxes) {
    OpenCensus::Trace::SpanBuilder::PieceBuilder.new \
      max_attributes: 0,
      max_stack_frames: 0,
      max_annotations: 0,
      max_message_events: 0,
      max_links: 0,
      max_string_length: 0
  }
  let(:builder_with_default_maxes) {
    OpenCensus::Trace::SpanBuilder::PieceBuilder.new
  }

  describe "truncatable_string" do
    it "should return the whole string for a short ascii string" do
      ts = builder_with_small_maxes.truncatable_string "hello"
      ts.value.must_equal "hello"
      ts.truncated_byte_count.must_equal 0
    end

    it "should return a truncated long ascii string" do
      ts = builder_with_small_maxes.truncatable_string "this is a longer string"
      ts.value.must_equal "this is a "
      ts.truncated_byte_count.must_equal 13
    end

    it "should handle a short string with long byte length" do
      ts = builder_with_small_maxes.truncatable_string "∫∫∫∫∫"
      ts.value.must_equal "∫∫∫"
      ts.truncated_byte_count.must_equal 6
    end

    it "should handle a long string beginning with long characters" do
      ts = builder_with_small_maxes.truncatable_string "∫∫∫aa"
      ts.value.must_equal "∫∫∫a"
      ts.truncated_byte_count.must_equal 1
    end

    it "should handle a long string ending with long characters" do
      ts = builder_with_small_maxes.truncatable_string "aa∫∫∫"
      ts.value.must_equal "aa∫∫"
      ts.truncated_byte_count.must_equal 3
    end

    it "should handle a string of exactly the right byte length" do
      ts = builder_with_small_maxes.truncatable_string "∫∫a∫"
      ts.value.must_equal "∫∫a∫"
      ts.truncated_byte_count.must_equal 0
    end

    it "should not truncate when no maxes are in place" do
      ts = builder_with_no_maxes.truncatable_string "this is a longer string"
      ts.value.must_equal "this is a longer string"
      ts.truncated_byte_count.must_equal 0
    end

    it "should honor default maxes" do
      default_max = OpenCensus::Trace::Config.default_max_string_length
      str = "*" * (default_max + 10)
      ts = builder_with_default_maxes.truncatable_string str
      ts.value.must_equal("*" * default_max)
      ts.truncated_byte_count.must_equal 10
    end
  end

  describe "attribute_pieces" do
    it "should keep an entire hash that is under the max" do
      input = {a: 1, b: 2}
      result, dropped = builder_with_small_maxes.attribute_pieces input
      result.must_equal({"a" => 1, "b" => 2})
      dropped.must_equal 0
    end

    it "should drop hash entries past the max" do
      input = {a: 1, b: 2, c: 3, d: 4, e: 5}
      result, dropped = builder_with_small_maxes.attribute_pieces input
      result.must_equal({"a" => 1, "b" => 2, "c" => 3})
      dropped.must_equal 2
    end

    it "should convert out of range integers to strings" do
      input = {a: 99999999999999999999, b: -99999999999999999999}
      result, dropped = builder_with_small_maxes.attribute_pieces input
      result["a"].value.must_equal "9999999999"
      result["a"].truncated_byte_count.must_equal 10
      result["b"].value.must_equal "-999999999"
      result["b"].truncated_byte_count.must_equal 11
      dropped.must_equal 0
    end

    it "should convert strings to TruncatableStrings" do
      input = {a: "∫∫∫∫∫", b: "hiho"}
      result, dropped = builder_with_small_maxes.attribute_pieces input
      result["a"].value.must_equal "∫∫∫"
      result["a"].truncated_byte_count.must_equal 6
      result["b"].value.must_equal "hiho"
      result["b"].truncated_byte_count.must_equal 0
      dropped.must_equal 0
    end

    it "should keep booleans and TruncatableStrings" do
      ts = OpenCensus::Trace::TruncatableString.new "asdf",
                                                    truncated_byte_count: 20
      input = {a: true, b: false, c: ts}
      result, dropped = builder_with_small_maxes.attribute_pieces input
      result.must_equal({"a" => true, "b" => false, "c" => ts})
      dropped.must_equal 0
    end

    it "should keep an entire hash if there is no max" do
      input = {a: 1, b: 2, c: 3, d: 4, e: 5}
      result, dropped = builder_with_no_maxes.attribute_pieces input
      result.must_equal({"a" => 1, "b" => 2, "c" => 3, "d" => 4, "e" => 5})
      dropped.must_equal 0
    end
  end

  describe "stack_trace_pieces" do
    it "should keep small traces" do
      input = ["a", "b"]
      result, dropped = builder_with_small_maxes.stack_trace_pieces input
      result.must_equal ["a", "b"]
      dropped.must_equal 0
    end

    it "should drop entries in large traces" do
      input = ["a", "b", "c", "d", "e"]
      result, dropped = builder_with_small_maxes.stack_trace_pieces input
      result.must_equal ["a", "b", "c"]
      dropped.must_equal 2
    end

    it "should keep an entire trace if there is no max" do
      input = ["a", "b", "c", "d", "e"]
      result, dropped = builder_with_no_maxes.stack_trace_pieces input
      result.must_equal ["a", "b", "c", "d", "e"]
      dropped.must_equal 0
    end
  end

  describe "status_piece" do
    it "should be nil if nothing passed in" do
      result = builder_with_small_maxes.status_piece nil, nil
      result.must_be_nil
    end

    it "should create a status if only a code is passed in" do
      result = builder_with_small_maxes.status_piece 200, nil
      result.code.must_equal 200
      result.message.must_equal ""
    end

    it "should create a status if only a message is passed in" do
      result = builder_with_small_maxes.status_piece nil, "hi"
      result.code.must_equal 0
      result.message.must_equal "hi"
    end
  end
end
