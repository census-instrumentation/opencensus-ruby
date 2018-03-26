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

describe OpenCensus::Trace::Exporters::Logger do
  let(:logger) {
    logger = ::Logger.new STDOUT
    logger.level = ::Logger::INFO
    logger.formatter = -> (_, _, _, msg) { msg }
    logger
  }

  describe "export" do
    let(:spans) { [OpenCensus::Trace::Span.new("traceid", "spanid", "name", Time.new, Time.new)] }

    it "should emit data for a covered log level" do
      exporter = OpenCensus::Trace::Exporters::Logger.new logger, level: ::Logger::INFO
      out, _err = capture_subprocess_io do
        exporter.export spans
      end

      out.wont_be_empty
    end

    it "should not emit data for a low log level" do
      exporter = OpenCensus::Trace::Exporters::Logger.new logger, level: ::Logger::DEBUG
      out, _err = capture_subprocess_io do
        exporter.export spans
      end

      out.must_be_empty
    end
  end

  describe "span format" do
    let(:root_context) { OpenCensus::Trace::SpanContext.create_root }
    let(:span1) do
      root_context
        .start_span("hello", kind: OpenCensus::Trace::SpanBuilder::SERVER)
        .put_attribute("foo", "bar")
        .put_annotation("some annotation", {"key" => "value"})
        .put_message_event(OpenCensus::Trace::SpanBuilder::SENT, 1234, 2345)
        .put_link("traceid", "spanid", OpenCensus::Trace::SpanBuilder::CHILD_LINKED_SPAN, {"key2" => "value2"})
        .set_status(200, "OK")
        .update_stack_trace
        .finish!
    end
    let(:exporter) { OpenCensus::Trace::Exporters::Logger.new logger, level: ::Logger::INFO }
    let(:output) do
      out, _err = capture_subprocess_io do
        exporter.export [span1.to_span]
      end
      JSON.parse(out).first
    end

    it "should serialize name" do
      output["name"].wont_be_empty
      output["name"].must_equal "hello"
    end

    it "should serialize kind" do
      output["kind"].wont_be_empty
      output["kind"].must_equal "SERVER"
    end

    it "should serialize attributes" do
      output["attributes"].must_equal({"foo" => "bar"})
      output["dropped_attributes_count"].must_equal 0
    end

    it "should serialize annotations" do
      output["time_events"].wont_be_empty
      output["time_events"].must_be_kind_of Array
      annotation = output["time_events"].first
      annotation.must_be_kind_of Hash
      annotation["time"].wont_be_empty
      annotation["description"].must_equal "some annotation"
      annotation["attributes"].must_equal({"key" => "value"})
      output["dropped_annotations_count"].must_equal 0
    end

    it "should serialize message events" do
      output["time_events"].wont_be_empty
      output["time_events"].must_be_kind_of Array
      message_event = output["time_events"].last
      message_event.must_be_kind_of Hash
      message_event["time"].wont_be_empty
      message_event["type"].must_equal "SENT"
      message_event["id"].must_equal 1234
      message_event["uncompressed_size"].must_equal 2345
      message_event["compressed_size"].must_be_nil
      output["dropped_message_events_count"].must_equal 0
    end

    it "should serialize links" do
      output["links"].wont_be_empty
      output["links"].must_be_kind_of Array
      link = output["links"].first
      link.must_be_kind_of Hash
      link["trace_id"].must_equal "traceid"
      link["span_id"].must_equal "spanid"
      link["type"].must_equal "CHILD_LINKED_SPAN"
      link["attributes"].must_equal({"key2" => "value2"})
      output["dropped_links_count"].must_equal 0
    end

    it "should serialize status" do
      output["status"].wont_be_nil
      output["status"].must_be_kind_of Hash
      output["status"]["code"].must_equal 200
      output["status"]["message"].must_equal "OK"
    end

    it "should serialize stack trace" do
      output["stack_trace"].wont_be_empty
      output["stack_trace"].must_be_kind_of Array
    end
  end
end
