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

require "opencensus/trace/integrations/sidekiq_middleware"

describe OpenCensus::Trace::Integrations::SidekiqMiddleware do
  subject { OpenCensus::Trace::Integrations::SidekiqMiddleware }

  RACK_APP_RESPONSE = [200, {}, ["Hello World!"]]

  class TestExporter
    attr_reader :spans

    def initialize
      @spans = []
    end

    def export spans
      @spans += spans
    end
  end

  Worker = Struct.new :jid

  let(:exporter) { TestExporter.new }
  let(:worker) { Worker.new "02a01088e781b06b881365fc" }
  let(:job) do
    {
      class: "Worker",
      args: %w[first_arg second_arg],
      retry: false,
      queue: "worker_queue",
      backtrace: true,
      dead: false,
      jid: "02a01088e781b06b881365fc",
      created_at: 1553686150.3007796,
      enqueued_at: 1553686150.3008194
    }.stringify_keys
  end
  let(:queue) { "worker_queue" }

  describe "basic job run" do
    let(:trace_prefix) { "trace_prefix" }
    let(:trace_attrs) { %w[class args] }
    let(:host_name) { "host_name" }
    let(:config) { OpenCensus::Trace.config.sidekiq }

    let(:middleware) { subject.new exporter: exporter }
    let(:response) {
      middleware.call worker, job, queue do
        # Simulated block to stub worker
      end
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

    describe "when trace name configuration values set" do
      before do
        @original_trace_prefix = config.trace_prefix
        config.trace_prefix = trace_prefix

        @original_trace_attrs = config.job_attrs_for_trace_name
        config.job_attrs_for_trace_name = trace_attrs

        @original_host_name = config.host_name
        config.host_name = host_name
      end
      after do
        config.trace_prefix = @original_trace_prefix
        config.job_attrs_for_trace_name = @original_trace_attrs
        config.host_name = @original_host_name
      end

      it "parses the job hash" do
        root_span.name.value
          .must_equal "trace_prefix/Worker/first_arg/second_arg"
      end
    end

    describe "when attribute configuration set" do
      before do
        @original_host_name = config.host_name
        config.host_name = host_name
      end
      after do
        config.host_name = @original_host_name
      end

      it "adds attributes to the span" do
        root_span.kind.must_equal :SERVER
        root_span.attributes["http.host"].value.must_equal "host_name"
      end
    end
    
    describe "when custom sample proc set" do
      describe "when sample proc returns false" do
        let(:sample_proc) { ->(_job) { false } }
        before do
          @original_sample_proc = config.sample_proc
          config.sample_proc = sample_proc
        end
        after do
          config.sample_proc = @original_sample_proc
        end

        it "does not take the sample" do
          spans.must_be_empty
        end
      end

      describe "when using default sample proc" do
        it "takes the sample" do
          spans.wont_be_empty
        end
      end
    end

  end

  describe "global configuration" do
    describe "default exporter" do
      let(:middleware) { subject.new exporter: exporter }

      it "should use the default Logger exporter" do
        out, _err = capture_subprocess_io do
          middleware.call worker, job, queue do
            # Simulated block to stub worker
            system "echo Some info"
          end
        end
        out.wont_be_empty
      end
    end

    describe "custom exporter" do
      let(:config) { OpenCensus::Trace.config }

      before do
        @original_exporter = config.exporter
        config.exporter = exporter
      end
      after do
        config.exporter = @original_exporter
      end
      let(:middleware) { subject.new }

      it "should capture the request" do
        middleware.call worker, job, queue do
          # Simulated block to stub worker
        end

        spans = exporter.spans
        spans.wont_be_empty
        spans.count.must_equal 1
      end
    end
  end
end
