require "test_helper"

require "google/protobuf/empty_pb"
require "google/protobuf/wrappers_pb"
require "grpc"
require "opencensus/trace/integrations/grpc_server_interceptor"

describe OpenCensus::Trace::Integrations::GrpcServerInterceptor do
  module TestRpc
    class Service
      include GRPC::GenericService

      self.marshal_class_method = :encode
      self.unmarshal_class_method = :decode
      self.service_name = "test.TestRpc"

      rpc :HelloRpc, Google::Protobuf::StringValue, Google::Protobuf::Empty
    end
  end

  class TestService < TestRpc::Service
    def hello_rpc(req, call)
      # Do nothing
    end
  end

  class MockedExporter
    attr_reader :spans

    def initialize
      @spans = []
    end

    def export spans
      @spans += spans
    end
  end

  MockedCall = Struct.new(:metadata)

  let(:exporter) { MockedExporter.new }
  let(:request) { Google::Protobuf::StringValue.new(value: "World") }
  let(:call) { MockedCall.new(metadata) }
  let(:method_object) { TestService.new.method(:hello_rpc) }

  describe "basic request" do
    let(:interceptor) { OpenCensus::Trace::Integrations::GrpcServerInterceptor.new exporter: exporter }
    let(:metadata) {
      {
        "user-agent" => "Google Chrome".encode(Encoding::ASCII_8BIT),
      }
    }
    let(:spans) do
      # make sure the request is processed
      interceptor.request_response(
        request: request, call: call, method: method_object) {}
      exporter.spans
    end
    let(:root_span) { spans.first }

    it "captures spans" do
      spans.wont_be_empty
      spans.count.must_equal 1
    end

    it "parses the request path" do
      root_span.name.value.must_equal "test.TestRpc/HelloRpc"
    end

    it "captures the response status code" do
      root_span.status.wont_be_nil
      root_span.status.code.must_equal OpenCensus::Trace::Status::OK
    end

    it "adds attributes to the span" do
      root_span.kind.must_equal :SERVER
      root_span.attributes["http.method"].value.must_equal "POST"
      root_span.attributes["http.path"].value.must_equal "/test.TestRpc/HelloRpc"
      root_span.attributes["http.user_agent"].value.must_equal "Google Chrome"
    end
  end

  describe "failure response" do
    let(:interceptor) { OpenCensus::Trace::Integrations::GrpcServerInterceptor.new exporter: exporter }
    let(:metadata) { {} }

    it "captures the response status code" do
      assert_raises GRPC::NotFound do
        interceptor.request_response \
          request: request,
          call: call,
          method: method_object do
          raise GRPC::NotFound
        end
      end
      root_span = exporter.spans.first

      root_span.status.wont_be_nil
      root_span.status.code.must_equal OpenCensus::Trace::Status::NOT_FOUND
    end
  end

  describe "global configuration" do
    let(:metadata) { {} }

    describe "default exporter" do
      let(:interceptor) { OpenCensus::Trace::Integrations::GrpcServerInterceptor.new  }

      it "should use the default Logger exporter" do
        out, _err = capture_subprocess_io do
          interceptor.request_response(
            request: request, call: call, method: method_object) {}
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
      let(:interceptor) { OpenCensus::Trace::Integrations::GrpcServerInterceptor.new  }

      it "should capture the request" do
        interceptor.request_response(
          request: request, call: call, method: method_object) {}

        spans = exporter.spans
        spans.wont_be_empty
        spans.count.must_equal 1
      end
    end
  end

  describe "trace context formatting" do
    let(:interceptor) { OpenCensus::Trace::Integrations::GrpcServerInterceptor.new exporter: exporter }

    describe "metadata with valid grpc-trace-bin" do
      let(:metadata) {
        {
          "grpc-trace-bin" => OpenCensus::Trace::Formatters::Binary.new.serialize(span_context),
        }
      }
      let(:span_context) {
        OpenCensus::Trace::TraceContextData.new(
          "0123456789abcdef0123456789abcdef",  # trace_id
          "0123456789abcdef",                  # span_id
          0,                                   # trace_options
        )
      }

      it "parses trace-context header from rack environment" do
        interceptor.request_response(
          request: request, call: call, method: method_object) {}
        root_span = exporter.spans.first

        root_span.trace_id.must_equal "0123456789abcdef0123456789abcdef"
        root_span.parent_span_id.must_equal "0123456789abcdef"
      end
    end

    describe "metadata with missing grpc-trace-bin" do
      let(:metadata) { {} }

      it "falls back to default for missing header" do
        interceptor.request_response(
          request: request, call: call, method: method_object) {}
        root_span = exporter.spans.first

        root_span.trace_id.must_match %r{^[0-9a-f]{32}$}
        root_span.parent_span_id.must_be_empty
      end
    end

    describe "metadata with invalid grpc-trace-bin" do
      let(:metadata) {
        {
          "grpc-trace-bin" => "invalid".encode(Encoding::ASCII_8BIT),
        }
      }

      it "falls back to default for invalid trace-context version" do
        interceptor.request_response(
          request: request, call: call, method: method_object) {}
        root_span = exporter.spans.first

        root_span.trace_id.must_match %r{^[0-9a-f]{32}$}
        root_span.parent_span_id.must_be_empty
      end
    end
  end

  describe "span modifier" do
    let(:interceptor) {
      OpenCensus::Trace::Integrations::GrpcServerInterceptor.new(
        exporter: exporter,
        span_modifier: span_modifier
      )
    }
    let(:span_modifier) {
      -> (span, request, call, method) {
        span.put_attribute "test.test_attribute", "dummy-value"
      }
    }
    let(:metadata) { {} }

    it "modifies a root span" do
      interceptor.request_response(
        request: request, call: call, method: method_object) {}
      root_span = exporter.spans.first

      root_span.attributes["test.test_attribute"].value.must_equal "dummy-value"
    end
  end
end
