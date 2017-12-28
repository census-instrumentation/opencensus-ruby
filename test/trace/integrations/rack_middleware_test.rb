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

    it "parses the request path" do
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
