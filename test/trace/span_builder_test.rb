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
      span.attributes["foo"].must_equal "bar"
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
      annotation.description.must_equal "some message"
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
