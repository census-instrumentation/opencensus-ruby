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

describe OpenCensus::Trace::SpanContext do
  describe "create_root" do
    it "populates defaults" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      span_context.parent.must_be_nil
      span_context.root.must_be_same_as span_context
      span_context.trace_id.must_match %r{^[0-9a-f]{32}$}
      span_context.span_id.must_equal ""
      span_context.trace_options.must_equal 0
    end

    it "parses a directly given Trace-Context header" do
      header = "00-0123456789ABCDEF0123456789abcdef-0123456789ABCdef-01"
      span_context = OpenCensus::Trace::SpanContext.create_root header: header
      span_context.parent.must_be_nil
      span_context.root.must_be_same_as span_context
      span_context.trace_id.must_equal "0123456789abcdef0123456789abcdef"
      span_context.span_id.must_equal "0123456789abcdef"
      span_context.trace_options.must_equal 1
      span_context.to_trace_context_header.must_equal \
        "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01"
    end

    it "parses trace-context header from rack environment" do
      env = {
        "HTTP_TRACE_CONTEXT" =>
          "00-0123456789ABCDEF0123456789abcdef-0123456789ABCdef-01"
      }
      span_context = OpenCensus::Trace::SpanContext.create_root rack_env: env
      span_context.parent.must_be_nil
      span_context.root.must_be_same_as span_context
      span_context.trace_id.must_equal "0123456789abcdef0123456789abcdef"
      span_context.span_id.must_equal "0123456789abcdef"
      span_context.trace_options.must_equal 1
      span_context.to_trace_context_header.must_equal \
        "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01"
    end

    it "falls back to default for a missing header" do
      env = {
        "HTTP_TRACE_CONTEXT1" =>
          "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01"
      }
      span_context = OpenCensus::Trace::SpanContext.create_root rack_env: env
      span_context.parent.must_be_nil
      span_context.root.must_be_same_as span_context
      span_context.trace_id.must_match %r{^[0-9a-f]{32}$}
      span_context.span_id.must_equal ""
      span_context.trace_options.must_equal 0
    end

    it "falls back to default for an invalid version" do
      env = {
        "HTTP_TRACE_CONTEXT" =>
          "ff-0123456789abcdef0123456789abcdef-0123456789abcdef-01"
      }
      span_context = OpenCensus::Trace::SpanContext.create_root rack_env: env
      span_context.parent.must_be_nil
      span_context.root.must_be_same_as span_context
      span_context.trace_id.must_match %r{^[0-9a-f]{32}$}
      span_context.span_id.must_equal ""
      span_context.trace_options.must_equal 0
    end
  end

  describe "start_span" do
    it "creates the correct span" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      span = span_context.start_span "hello"
      span.trace_id.must_equal span_context.trace_id
      span.name.must_equal "hello"
      span.start_time.wont_be_nil
      span.end_time.must_be_nil
      span.span_id.must_equal span.context.span_id
      span.parent_span_id.must_equal ""
      span.context.this_span.must_be_same_as span
    end

    it "finishes when given a block" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      span = span_context.in_span "hello" do |block_span|
        block_span.start_time.wont_be_nil
        block_span.end_time.must_be_nil
        block_span
      end
      span.start_time.wont_be_nil
      span.end_time.wont_be_nil
    end

    it "creates a hierarchy of contexts" do
      root_context = OpenCensus::Trace::SpanContext.create_root
      span1 = root_context.start_span "hello"
      context1 = span1.context
      span2 = context1.start_span "world"
      context2 = span2.context

      context2.wont_be_same_as context1
      context1.wont_be_same_as root_context
      context2.parent.must_be_same_as context1
      context1.parent.must_be_same_as root_context
      root_context.parent.must_be_nil
      context2.root.must_be_same_as root_context
      context1.root.must_be_same_as root_context
      root_context.root.must_be_same_as root_context
    end
  end
end
