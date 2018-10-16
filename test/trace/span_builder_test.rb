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

  describe "kind" do
    it "should default to unspecified" do
      span_builder.kind.must_equal :SPAN_KIND_UNSPECIFIED
    end

    it "should be settable" do
      span_builder.kind = :SERVER
      span_builder.kind.must_equal :SERVER
    end

    it "should be captured" do
      span_builder.kind = :CLIENT
      span = span_builder.to_span
      span.kind.must_equal :CLIENT
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

  describe "finish!" do
    it "should not allow you to finish more than once" do
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
    let(:ret) { span_builder.set_status(0, "OK") }

    it "should be chainable" do
      ret.must_be_instance_of OpenCensus::Trace::SpanBuilder
      ret.must_be_same_as span_builder
    end

    it "should be captured" do
      span = ret.to_span
      span.status.wont_be_nil
      status = span.status
      status.code.must_equal 0
      status.message.must_equal "OK"
    end
  end

  describe "set_http_status" do
    it "should be chainable" do
      ret = span_builder.set_http_status(200, "OK")
      ret.must_be_instance_of OpenCensus::Trace::SpanBuilder
      ret.must_be_same_as span_builder
    end

    it "should capture 200" do
      ret = span_builder.set_http_status(200, "OK")
      span = ret.to_span
      span.status.wont_be_nil
      status = span.status
      status.code.must_equal OpenCensus::Trace::Status::OK
      status.message.must_equal "OK"
    end

    it "should capture 404" do
      ret = span_builder.set_http_status(404, "Not found")
      span = ret.to_span
      span.status.wont_be_nil
      status = span.status
      status.code.must_equal OpenCensus::Trace::Status::NOT_FOUND
      status.message.must_equal "Not found"
    end

    it "should capture 500" do
      ret = span_builder.set_http_status(500, "Unknown error")
      span = ret.to_span
      span.status.wont_be_nil
      status = span.status
      status.code.must_equal OpenCensus::Trace::Status::UNKNOWN
      status.message.must_equal "Unknown error"
    end
  end

  describe "same_process_as_parent_span calculation" do
    it "defaults to nil" do
      sb1 = span_context.start_span "span1"
      sb1.finish!
      sb1.to_span.same_process_as_parent_span.must_be_nil
    end

    it "results in true for a child span" do
      sb1 = span_context.start_span "span1"
      sb2 = sb1.context.start_span "span2"
      sb2.finish!
      sb2.to_span.same_process_as_parent_span.must_equal true
    end

    it "results in false when the context says so" do
      trace_context = OpenCensus::Trace::TraceContextData.new \
        "0123456789abcdef0123456789abcdef", "0123456789abcdef", 1
      remote_context = OpenCensus::Trace::SpanContext.create_root \
        same_process_as_parent: false, trace_context: trace_context
      sb1 = remote_context.start_span "span1"
      sb1.finish!
      sb1.to_span.same_process_as_parent_span.must_equal false
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

    it "should truncate a string that doesn't match char boundary" do
      ts = builder_with_small_maxes.truncatable_string "∫∫∫∫∫"
      ts.value.must_equal "∫∫∫"
      ts.truncated_byte_count.must_equal 6
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
      default_max = OpenCensus::Trace.config.default_max_string_length
      str = "*" * (default_max + 10)
      ts = builder_with_default_maxes.truncatable_string str
      ts.value.must_equal("*" * default_max)
      ts.truncated_byte_count.must_equal 10
    end
  end

  describe "convert_attributes" do
    it "should keep an entire hash that is under the max" do
      input = {a: 1, b: 2}
      result = builder_with_small_maxes.convert_attributes input
      result.must_equal({"a" => 1, "b" => 2})
    end

    it "should drop hash entries past the max" do
      input = {a: 1, b: 2, c: 3, d: 4, e: 5}
      result = builder_with_small_maxes.convert_attributes input
      result.must_equal({"a" => 1, "b" => 2, "c" => 3})
    end

    it "should convert out of range integers to strings" do
      input = {a: 99999999999999999999, b: -99999999999999999999}
      result = builder_with_small_maxes.convert_attributes input
      result["a"].value.must_equal "9999999999"
      result["a"].truncated_byte_count.must_equal 10
      result["b"].value.must_equal "-999999999"
      result["b"].truncated_byte_count.must_equal 11
    end

    it "should convert strings to TruncatableStrings" do
      input = {a: "∫∫∫∫∫", b: "hiho"}
      result = builder_with_small_maxes.convert_attributes input
      result["a"].value.must_equal "∫∫∫"
      result["a"].truncated_byte_count.must_equal 6
      result["b"].value.must_equal "hiho"
      result["b"].truncated_byte_count.must_equal 0
    end

    it "should keep booleans and TruncatableStrings" do
      ts = OpenCensus::Trace::TruncatableString.new "asdf",
                                                    truncated_byte_count: 20
      input = {a: true, b: false, c: ts}
      result = builder_with_small_maxes.convert_attributes input
      result.must_equal({"a" => true, "b" => false, "c" => ts})
    end

    it "should keep an entire hash if there is no max" do
      input = {a: 1, b: 2, c: 3, d: 4, e: 5}
      result = builder_with_no_maxes.convert_attributes input
      result.must_equal({"a" => 1, "b" => 2, "c" => 3, "d" => 4, "e" => 5})
    end
  end

  describe "truncate_stack_trace" do
    it "should keep small traces" do
      input = ["a", "b"]
      result = builder_with_small_maxes.truncate_stack_trace input
      result.must_equal ["a", "b"]
    end

    it "should drop entries in large traces" do
      input = ["a", "b", "c", "d", "e"]
      result = builder_with_small_maxes.truncate_stack_trace input
      result.must_equal ["a", "b", "c"]
    end

    it "should keep an entire trace if there is no max" do
      input = ["a", "b", "c", "d", "e"]
      result = builder_with_no_maxes.truncate_stack_trace input
      result.must_equal ["a", "b", "c", "d", "e"]
    end
  end

  describe "convert_status" do
    it "should be nil if nothing passed in" do
      result = builder_with_small_maxes.convert_status nil, nil
      result.must_be_nil
    end

    it "should create a status if only a code is passed in" do
      result = builder_with_small_maxes.convert_status 200, nil
      result.code.must_equal 200
      result.message.must_equal ""
    end

    it "should create a status if only a message is passed in" do
      result = builder_with_small_maxes.convert_status nil, "hi"
      result.code.must_equal 0
      result.message.must_equal "hi"
    end
  end
end
