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

describe OpenCensus::Trace do
  let(:simple_context) { OpenCensus::Trace::SpanContext.create_root }
  let(:header) { "00-0123456789abcdef0123456789abcdef-0123456789abcdef-00" }
  let(:trace_context) do
    OpenCensus::Trace::Formatters::TraceContextData.new \
      "0123456789abcdef0123456789abcdef", "0123456789abcdef", 1
  end

  describe "span context" do
    after {
      OpenCensus::Trace.unset_span_context
    }

    it "can be set and unset" do
      OpenCensus::Trace.span_context.must_be_nil
      OpenCensus::Trace.span_context = simple_context
      OpenCensus::Trace.span_context.must_equal simple_context
      OpenCensus::Trace.unset_span_context
      OpenCensus::Trace.span_context.must_be_nil
    end

    it "is initialized when a request trace starts" do
      OpenCensus::Trace.start_request_trace trace_context: trace_context
      OpenCensus::Trace.span_context.trace_id.must_equal \
        "0123456789abcdef0123456789abcdef"
      OpenCensus::Trace.span_context.span_id.must_equal \
        "0123456789abcdef"
      OpenCensus::Trace.span_context.root?.must_equal true
    end

    it "is cleared after a request trace block" do
      OpenCensus::Trace.start_request_trace trace_context: trace_context do |ctx|
        OpenCensus::Trace.span_context.must_equal ctx
      end
      OpenCensus::Trace.span_context.must_be_nil
    end
  end

  describe "default context" do
    before {
      OpenCensus::Trace.start_request_trace trace_context: trace_context
    }
    after {
      OpenCensus::Trace.unset_span_context
    }

    it "can start a span which changes the context" do
      OpenCensus::Trace.start_span "the span"
      OpenCensus::Trace.span_context.trace_id.must_equal \
        "0123456789abcdef0123456789abcdef"
      OpenCensus::Trace.span_context.span_id.wont_equal \
        "0123456789abcdef"
      OpenCensus::Trace.span_context.parent.span_id.must_equal \
        "0123456789abcdef"
    end

    it "can end the current span which restores the root context" do
      span = OpenCensus::Trace.start_span "the span"
      OpenCensus::Trace.end_span span
      OpenCensus::Trace.span_context.trace_id.must_equal \
        "0123456789abcdef0123456789abcdef"
      OpenCensus::Trace.span_context.span_id.must_equal \
        "0123456789abcdef"
      OpenCensus::Trace.span_context.root?.must_equal true
    end

    it "cannot end a foreign span" do
      foreign_span = simple_context.start_span "foreign span"
      OpenCensus::Trace.start_span "the span"
      -> () {
        OpenCensus::Trace.end_span foreign_span
      }.must_raise "The given span doesn't match the currently active span"
    end

    it "can start and end a span in a block" do
      OpenCensus::Trace.in_span "the span" do |span|
        OpenCensus::Trace.span_context.trace_id.must_equal \
          "0123456789abcdef0123456789abcdef"
        OpenCensus::Trace.span_context.span_id.wont_equal \
          "0123456789abcdef"
        OpenCensus::Trace.span_context.parent.span_id.must_equal \
          "0123456789abcdef"
      end
      OpenCensus::Trace.span_context.trace_id.must_equal \
        "0123456789abcdef0123456789abcdef"
      OpenCensus::Trace.span_context.span_id.must_equal \
        "0123456789abcdef"
      OpenCensus::Trace.span_context.root?.must_equal true
    end
  end
end
