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
  class TestApp
    def call env
      [200, {}, ["Hello World!"]]
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

  let(:app) { TestApp.new }
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
      root_span.name.must_equal "/hello/world"
    end

    it "captures the response status code" do
      root_span.status.wont_be_nil
      root_span.status.code.must_equal 200
    end

    it "adds attributes to the span" do
      root_span.attributes["/http/method"].must_equal "GET"
      root_span.attributes["/http/url"].must_equal "https://www.google.com/hello/world"
      root_span.attributes["/http/host"].must_equal "www.google.com"
      root_span.attributes["/http/client_protocol"].must_equal "https"
      root_span.attributes["/http/user_agent"].must_equal "Google Chrome"
      root_span.attributes["/pid"].wont_be_empty
      root_span.attributes["/tid"].wont_be_empty
    end

    it "adds trace context header to response" do
      response.must_be_kind_of Array
      response.size.must_equal 3
      response[1]["Trace-Context"].wont_be_empty
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
        @original_exporter = OpenCensus::Trace::Config.exporter
        OpenCensus::Trace::Config.exporter = exporter
      end
      after { OpenCensus::Trace::Config.exporter = @original_exporter }
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
  end
end
