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
    end

    it "parses x-cloud-trace header from rack environment" do
      env = {
        "HTTP_X_CLOUD_TRACE" =>
          "0123456789ABCDEF0123456789abcdef/81985529216486895;o=1"
      }
      span_context = OpenCensus::Trace::SpanContext.create_root rack_env: env
      span_context.parent.must_be_nil
      span_context.root.must_be_same_as span_context
      span_context.trace_id.must_equal "0123456789abcdef0123456789abcdef"
      span_context.span_id.must_equal "0123456789abcdef"
      span_context.trace_options.must_equal 1
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

  describe "context hierarchy" do
    let(:root_context) { OpenCensus::Trace::SpanContext.create_root }
    let(:span1) { root_context.start_span "hello" }
    let(:context1) { span1.context }
    let(:span2) { context1.start_span "world" }
    let(:context2) { span2.context }

    it "consists of distinct contexts" do
      context2.wont_be_same_as context1
      context1.wont_be_same_as root_context
    end

    it "supports getting context parents" do
      context2.parent.must_be_same_as context1
      context1.parent.must_be_same_as root_context
      root_context.parent.must_be_nil
    end

    it "supports getting the root context" do
      context2.root.must_be_same_as root_context
      context1.root.must_be_same_as root_context
      root_context.root.must_be_same_as root_context
      context2.root?.must_equal false
      context1.root?.must_equal false
      root_context.root?.must_equal true
    end

    it "supports contains" do
      root_context.contains?(context2).must_equal true
      root_context.contains?(context1).must_equal true
      root_context.contains?(root_context).must_equal true
      context1.contains?(root_context).must_equal false
      context2.contains?(context1).must_equal false
    end

    it "supports contained_span_builders" do
      context2   # Cause all spans to be built before expectations are run
      root_context.contained_span_builders.must_include span1
      root_context.contained_span_builders.must_include span2
      context1.contained_span_builders.wont_include span1
      context1.contained_span_builders.must_include span2
      context2.contained_span_builders.wont_include span1
      context2.contained_span_builders.wont_include span2
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

    it "captures the stack trace" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      span = span_context.start_span "hello"
      frame = span.instance_variable_get(:@stack_trace).first
      frame.label.must_match %r{^block}
      frame.path.must_match %r{span_context_test\.rb$}
    end

    it "honors span-scoped sampler" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      sampler = OpenCensus::Trace::Samplers::AlwaysSample.new
      span = span_context.start_span "hello", sampler: sampler
      span.sampled.must_equal true
      sampler = OpenCensus::Trace::Samplers::NeverSample.new
      span = span_context.start_span "hello", sampler: sampler
      span.sampled.must_equal false
    end
  end

  describe "in_span" do
    it "finishes at the end of the block" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      span = span_context.in_span "hello" do |block_span|
        block_span.start_time.wont_be_nil
        block_span.end_time.must_be_nil
        block_span
      end
      span.start_time.wont_be_nil
      span.end_time.wont_be_nil
    end

    it "captures the stack trace" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      span_context.in_span "hello" do |span|
        frame = span.instance_variable_get(:@stack_trace).first
        frame.label.must_match %r{^block}
        frame.path.must_match %r{span_context_test\.rb$}
      end
    end

    it "honors span-scoped sampler" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      sampler = OpenCensus::Trace::Samplers::AlwaysSample.new
      span_context.in_span "hello", sampler: sampler do |span|
        span.sampled.must_equal true
      end
      sampler = OpenCensus::Trace::Samplers::NeverSample.new
      span_context.in_span "hello", sampler: sampler do |span|
        span.sampled.must_equal false
      end
    end
  end

  describe "build_contained_spans" do
    let(:root_context) { OpenCensus::Trace::SpanContext.create_root }
    let(:span1) { root_context.start_span "hello" }
    let(:context1) { span1.context }
    let(:span2) { context1.start_span "world" }
    let(:context2) { span2.context }

    it "builds finished spans contained in the context" do
      span2.finish!
      span1.finish!
      spans = root_context.build_contained_spans
      spans.size.must_equal 2
    end

    it "omits unfinished spans" do
      span1.finish!
      spans = root_context.build_contained_spans
      spans.size.must_equal 1
      spans.first.name.value.must_equal "hello"
    end

    it "omits spans not contained in the context" do
      span2.finish!
      span1.finish!
      spans = context1.build_contained_spans
      spans.size.must_equal 1
      spans.first.name.value.must_equal "world"
    end
  end
end
