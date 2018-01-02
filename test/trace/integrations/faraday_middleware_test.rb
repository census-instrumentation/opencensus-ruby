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

require "opencensus/trace/integrations/faraday_middleware"

describe OpenCensus::Trace::Integrations::FaradayMiddleware do
  class TestApp
    def initialize code: 200, body: "ok"
      @code = code
      @body = body
    end
    def call env
      env[:status] = @code
      env[:body] = @body
      TestResponse.new env
    end
  end
  class TestResponse
    def initialize env
      @env = env
    end
    def on_complete
      yield @env
      @env
    end
  end

  def app code: 200, body: "ok"
    TestApp.new code: code, body: body
  end
  let(:root_context) { OpenCensus::Trace::SpanContext.create_root }

  describe "span_name option" do
    it "should default to DEFAULT_SPAN_NAME" do
      middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new \
        app, span_context: root_context
      env = {}
      middleware.call env
      spans = root_context.build_contained_spans

      spans.size.must_equal 1
      spans.first.name.value.must_equal \
        OpenCensus::Trace::Integrations::FaradayMiddleware::DEFAULT_SPAN_NAME
    end

    it "should honor a custom span name" do
      middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new \
        app, span_context: root_context, span_name: "my-span"
      env = {}
      middleware.call env
      spans = root_context.build_contained_spans

      spans.size.must_equal 1
      spans.first.name.value.must_equal "my-span"
    end

    it "should honor a callable span name" do
      middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new \
        app, span_context: root_context, span_name: ->(env) { env[:foo] }
      env = {foo: "bar"}
      middleware.call env
      spans = root_context.build_contained_spans

      spans.size.must_equal 1
      spans.first.name.value.must_equal "bar"
    end

    it "should honor per-request span name" do
      middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new \
        app, span_context: root_context
      env = {span_name: "my-span"}
      middleware.call env
      spans = root_context.build_contained_spans

      spans.size.must_equal 1
      spans.first.name.value.must_equal "my-span"
    end
  end

  describe "default span context" do
    it "should use the thread-scoped span context" do
      OpenCensus::Trace.start_request_trace
      begin
        middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new app
        env = {}
        middleware.call env
        spans = OpenCensus::Trace.span_context.build_contained_spans
        spans.size.must_equal 1
      ensure
        OpenCensus::Trace.unset_span_context
      end
    end

    it "shouldn't fail if there is no span context" do
      middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new app
      env = {}
      middleware.call env
    end
  end

  describe "making a request" do
    it "should add attributes to the span" do
      middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new \
        app(code: 200, body: "ok"), span_context: root_context
      env = {
        method: "POST",
        url: "https://www.google.com/",
        body: "Hello"
      }
      middleware.call env
      span = root_context.build_contained_spans.first

      span.status.wont_be_nil
      span.status.code.must_equal 200
      span.attributes["/http/method"].value.must_equal "POST"
      span.attributes["/http/url"].value.must_equal "https://www.google.com/"
      span.attributes["/rpc/request/size"].must_equal 5
      span.attributes["/rpc/response/size"].must_equal 2
      span.attributes["/rpc/status_code"].must_equal 200
    end

    it "should not add body attributes if there is no body" do
      middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new \
        app(code: 200, body: nil), span_context: root_context
      env = {
        method: "POST",
        url: "https://www.google.com/"
      }
      middleware.call env
      span = root_context.build_contained_spans.first

      span.attributes["/rpc/request/size"].must_be_nil
      span.attributes["/rpc/response/size"].must_be_nil
    end

    it "should provide the correct trace context header" do
      middleware = OpenCensus::Trace::Integrations::FaradayMiddleware.new \
        app(code: 200, body: nil), span_context: root_context
      env = {
        method: "POST",
        url: "https://www.google.com/"
      }
      middleware.call env
      span = root_context.build_contained_spans.first

      header = env[:request_headers]["Trace-Context"]
      header.must_match %r{^00-#{span.trace_id}-#{span.span_id}}
    end
  end
end
