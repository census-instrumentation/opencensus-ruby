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
    let(:trace_context) do
      OpenCensus::Trace::TraceContextData.new \
        "0123456789abcdef0123456789abcdef", "0123456789abcdef", 1
    end
    it "populates defaults" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      span_context.parent.must_be_nil
      span_context.root.must_be_same_as span_context
      span_context.trace_id.must_match %r{^[0-9a-f]{32}$}
      span_context.span_id.must_equal ""
      span_context.trace_options.must_equal 0
    end

    it "uses a parsed trace context" do
      span_context = OpenCensus::Trace::SpanContext.create_root trace_context: trace_context
      span_context.parent.must_be_nil
      span_context.root.must_be_same_as span_context
      span_context.trace_id.must_equal "0123456789abcdef0123456789abcdef"
      span_context.span_id.must_equal "0123456789abcdef"
      span_context.trace_options.must_equal 1
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
      frame.must_match %r{block}
      frame.must_match %r{span_context_test\.rb}
    end

    it "honors span-scoped sampler" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      sampler1 = OpenCensus::Trace::Samplers::AlwaysSample.new
      span1 = span_context.start_span "hello", sampler: sampler1
      span1.sampled?.must_equal true
      sampler2 = OpenCensus::Trace::Samplers::NeverSample.new
      span2 = span_context.start_span "hello", sampler: sampler2
      span2.sampled?.must_equal false
    end

    it "honors true and false as span-scoped samplers" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      span1 = span_context.start_span "hello", sampler: true
      span1.sampled?.must_equal true
      span2 = span_context.start_span "hello", sampler: false
      span2.sampled?.must_equal false
    end

    it "honors local parent sampler" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      sampler = OpenCensus::Trace::Samplers::NeverSample.new
      span1 = span_context.start_span "hello", sampler: sampler
      span1.sampled?.must_equal false
      span2 = span1.context.start_span "world"
      span2.sampled?.must_equal false
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
        frame.must_match %r{block}
        frame.must_match %r{span_context_test\.rb}
      end
    end

    it "honors span-scoped sampler" do
      span_context = OpenCensus::Trace::SpanContext.create_root
      sampler1 = OpenCensus::Trace::Samplers::AlwaysSample.new
      span_context.in_span "hello", sampler: sampler1 do |span|
        span.sampled?.must_equal true
      end
      sampler2 = OpenCensus::Trace::Samplers::NeverSample.new
      span_context.in_span "hello", sampler: sampler2 do |span|
        span.sampled?.must_equal false
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

    it "omits unsampled spans" do
      never_sample = OpenCensus::Trace::Samplers::NeverSample.new
      s1 = root_context.start_span "hello"
      s2 = s1.context.start_span "world", sampler: never_sample
      s2.finish!
      s1.finish!
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
