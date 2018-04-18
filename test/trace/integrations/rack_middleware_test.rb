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

require "opencensus/trace/integrations/rack_middleware"

describe OpenCensus::Trace::Integrations::RackMiddleware do
  RACK_APP_RESPONSE = [200, {}, ["Hello World!"]]

  class TestRackApp
    def call env
      RACK_APP_RESPONSE
    end
  end

  class TestExporter
    attr_reader :spans

    def initialize
      @spans = []
    end

    def export spans
      @spans += spans
    end
  end

  let(:app) { TestRackApp.new }
  let(:exporter) { TestExporter.new }

  describe "basic request" do
    let(:middleware) { OpenCensus::Trace::Integrations::RackMiddleware.new app, exporter: exporter }
    let(:response) {
      env = {
        "SCRIPT_NAME" => "",
        "PATH_INFO" => "/hello/world",
        "HTTP_HOST" => "www.google.com",
        "REQUEST_METHOD" => "GET",
        "SERVER_PROTOCOL" => "https",
        "HTTP_USER_AGENT" => "Google Chrome",
      }
      middleware.call env
    }
    let(:spans) do
      response # make sure the request is processed
      exporter.spans
    end
    let(:root_span) { spans.first }

    it "captures spans" do
      spans.wont_be_empty
      spans.count.must_equal 1
    end

    it "parses the request path" do
      root_span.name.value.must_equal "/hello/world"
    end

    it "captures the response status code" do
      root_span.status.wont_be_nil
      root_span.status.code.must_equal 200
    end

    it "adds attributes to the span" do
      root_span.kind.must_equal :SERVER
      root_span.attributes["/http/method"].value.must_equal "GET"
      root_span.attributes["/http/url"].value.must_equal "https://www.google.com/hello/world"
      root_span.attributes["/http/host"].value.must_equal "www.google.com"
      root_span.attributes["/http/client_protocol"].value.must_equal "https"
      root_span.attributes["/http/user_agent"].value.must_equal "Google Chrome"
      root_span.attributes["/pid"].value.wont_be_empty
      root_span.attributes["/tid"].value.wont_be_empty
    end
  end

  describe "global configuration" do
    describe "default exporter" do
      let(:middleware) { OpenCensus::Trace::Integrations::RackMiddleware.new app }

      it "should use the default Logger exporter" do
        env = {
          "SCRIPT_NAME" => "",
          "PATH_INFO" => "/hello/world"
        }
        out, _err = capture_subprocess_io do
          middleware.call env
        end
        out.wont_be_empty
      end
    end

    describe "custom exporter" do
      before do
        @original_exporter = OpenCensus::Trace.config.exporter
        OpenCensus::Trace.config.exporter = exporter
      end
      after do
        OpenCensus::Trace.config.exporter = @original_exporter
      end
      let(:middleware) { OpenCensus::Trace::Integrations::RackMiddleware.new app }

      it "should capture the request" do
        env = {
          "SCRIPT_NAME" => "",
          "PATH_INFO" => "/hello/world"
        }
        middleware.call env

        spans = exporter.spans
        spans.wont_be_empty
        spans.count.must_equal 1
      end
    end

    describe "default sampler" do
      let(:middleware) { OpenCensus::Trace::Integrations::RackMiddleware.new app, exporter: exporter }

      it "should use the default AlwaysSample sampler" do
        env = {
          "SCRIPT_NAME" => "",
          "PATH_INFO" => "/hello/world"
        }
        middleware.call env
        spans = exporter.spans
        spans.wont_be_empty
      end
    end

    describe "custom sampler" do
      let(:middleware) { OpenCensus::Trace::Integrations::RackMiddleware.new app, exporter: exporter, sampler: OpenCensus::Trace::Samplers::NeverSample.new }

      it "should use the new sampler provided" do
        env = {
          "SCRIPT_NAME" => "",
          "PATH_INFO" => "/hello/world"
        }
        middleware.call env

        spans = exporter.spans
        spans.must_be_empty
      end
    end
  end

  describe "trace context formatting" do
    let(:middleware) { OpenCensus::Trace::Integrations::RackMiddleware.new app, exporter: exporter }
    it "parses trace-context header from rack environment" do
      env = {
        "HTTP_TRACE_CONTEXT" =>
          "00-0123456789ABCDEF0123456789abcdef-0123456789ABCdef-01"
      }
      resp = middleware.call env
      root_span = exporter.spans.first

      resp.must_equal RACK_APP_RESPONSE
      root_span.trace_id.must_equal "0123456789abcdef0123456789abcdef"
      root_span.parent_span_id.must_equal "0123456789abcdef"
    end

    it "parses x-cloud-trace header from rack environment" do
      env = {
        "HTTP_X_CLOUD_TRACE" =>
          "0123456789ABCDEF0123456789abcdef/81985529216486895;o=1"
      }
      resp = middleware.call env
      root_span = exporter.spans.first

      resp.must_equal RACK_APP_RESPONSE
      root_span.trace_id.must_equal "0123456789abcdef0123456789abcdef"
      root_span.parent_span_id.must_equal "0123456789abcdef"
    end

    it "falls back to default for missing header" do
      env = {
        "HTTP_TRACE_CONTEXT1" =>
          "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01"
      }
      resp = middleware.call env
      root_span = exporter.spans.first

      resp.must_equal RACK_APP_RESPONSE
      root_span.trace_id.must_match %r{^[0-9a-f]{32}$}
      root_span.parent_span_id.must_be_empty
    end

    it "falls back to default for invalid trace-context version" do
      env = {
        "HTTP_TRACE_CONTEXT" =>
          "ff-0123456789abcdef0123456789abcdef-0123456789abcdef-01"
      }
      resp = middleware.call env
      root_span = exporter.spans.first

      resp.must_equal RACK_APP_RESPONSE
      root_span.trace_id.must_match %r{^[0-9a-f]{32}$}
      root_span.parent_span_id.must_be_empty
    end
  end
end
