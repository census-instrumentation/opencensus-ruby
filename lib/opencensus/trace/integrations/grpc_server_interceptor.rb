require "opencensus"

module OpenCensus
  module Trace
    module Integrations
      ##
      # # gRPC interceptor
      #
      # This is a interceptor for gRPC:
      #
      # * It wraps all incoming requests in a root span
      # * It exports the captured spans at the end of the request.
      #
      # Example:
      #
      #     require "opencensus/trace/integrations/grpc_server_interceptor"
      #
      #     server = GRPC::RpcServer.new(
      #       interceptors: [
      #         OpenCensus::Trace::Integrations::GrpcServerInterceptor.new,
      #       ]
      #     )
      #
      class GrpcServerInterceptor
        ##
        # A key we use to read the parent span context.
        #
        # @private
        #
        OPENCENSUS_TRACE_BIN_KEY = "grpc-trace-bin".freeze

        ##
        # @param [#export] exporter The exported used to export captured spans
        #     at the end of the request. Optional: If omitted, uses the exporter
        #     in the current config.
        # @param [#call] span_modifier Modify span if necessary. It takes span,
        # request, call, method as its parameters.
        #
        def initialize exporter: nil, span_modifier: nil
          @exporter = exporter || OpenCensus::Trace.config.exporter
          @span_modifier = span_modifier
          @formatter = Formatters::Binary.new
        end

        ##
        # Intercept a unary request response call.
        #
        # @param [Object] request
        # @param [GRPC::ActiveCall::SingleReqView] call
        # @param [Method] method
        #
        def request_response request:, call:, method:, &block
          context_bin = call.metadata[OPENCENSUS_TRACE_BIN_KEY]
          context = context_bin ? deserialize(context_bin) : nil

          Trace.start_request_trace \
            trace_context: context,
            same_process_as_parent: false do |span_context|
            begin
              yield_with_trace(request, call, method, &block)
            ensure
              @exporter.export span_context.build_contained_spans
            end
          end
        end

        # NOTE: For now, we don't support server_streamer, client_streamer and
        # bidi_streamer

        private

        ##
        # @param [String] context_bin OpenCensus span context in binary format
        # @return [OpenCensus::Trace::TraceContextData, nil]
        #
        def deserialize context_bin
          @formatter.deserialize(context_bin)
        end

        ##
        # @param [Object] request
        # @param [GRPC::ActiveCall::SingleReqView] call
        # @param [Method] method
        #
        def yield_with_trace request, call, method
          Trace.in_span get_name(method) do |span|
            modify_span span, request, call, method

            start_request span, call, method
            begin
              grpc_ex = GRPC::Ok.new
              yield request: request, call: call, method: method
            rescue StandardError => e
              grpc_ex = to_grpc_ex(e)
              raise e
            ensure
              finish_request span, grpc_ex
            end
          end
        end

        ##
        # Span name is represented as $package.$service/$method
        # cf. https://github.com/census-instrumentation/opencensus-specs/blob/master/trace/gRPC.md#spans
        #
        # @param [Method] method
        # @return [String]
        #
        def get_name method
          "#{method.owner.service_name}/#{camelize(method.name.to_s)}"
        end

        ##
        # @param [Method] method
        # @return [String]
        #
        def get_path method
          "/" + get_name(method)
        end

        ##
        # @param [String] term
        # @return [String]
        #
        def camelize term
          term.split("_").map(&:capitalize).join
        end

        ##
        # Modify span by custom span modifier
        #
        # @param [OpenCensus::Trace::SpanBuilder] span
        # @param [Object] request
        # @param [GRPC::ActiveCall::SingleReqView] call
        # @param [Method] method
        #
        def modify_span span, request, call, method
          @span_modifier.call(span, request, call, method) if @span_modifier
        end

        ##
        # @param [OpenCensus::Trace::SpanBuilder] span
        # @param [GRPC::ActiveCall::SingleReqView] call
        # @param [Method] method
        #
        def start_request span, call, method
          span.kind = SpanBuilder::SERVER
          span.put_attribute "http.path", get_path(method)
          span.put_attribute "http.method", "POST" # gRPC always uses "POST"
          if call.metadata["user-agent"]
            span.put_attribute "http.user_agent", call.metadata["user-agent"]
          end
        end

        ##
        # @param [OpenCensus::Trace::SpanBuilder] span
        # @param [GRPC::BadStatus] exception
        #
        def finish_request span, exception
          # Set gRPC server status
          # https://github.com/census-instrumentation/opencensus-specs/blob/master/trace/gRPC.md#spans
          span.set_status exception.code
          span.put_attribute "http.status_code", to_http_status(exception)
        end

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/CyclomaticComplexity

        ##
        # cf. https://github.com/census-instrumentation/opencensus-specs/blob/master/trace/HTTP.md#mapping-from-http-status-codes-to-trace-status-codes
        #
        # @param [GRPC::BadStatus] exception
        # @return [Integer]
        #
        def to_http_status exception
          case exception
          when GRPC::Ok
            200
          when GRPC::InvalidArgument
            400
          when GRPC::DeadlineExceeded
            504
          when GRPC::NotFound
            404
          when GRPC::PermissionDenied
            403
          when GRPC::Unauthenticated
            401
          when GRPC::Aborted
            # For GRPC::Aborted, grpc-gateway uses 409. We do the same.
            # cf. https://github.com/grpc-ecosystem/grpc-gateway/blob/e8db07a3923d3f5c77dbcea96656afe43a2757a8/runtime/errors.go#L17-L58
            409
          when GRPC::ResourceExhausted
            429
          when GRPC::Unimplemented
            501
          when GRPC::Unavailable
            503
          when GRPC::Unknown
            # NOTE: This is not same with the correct mapping
            500
          else
            # NOTE: Here, we use 500 temporarily.
            500
          end
        end

        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/CyclomaticComplexity

        ##
        # @param [Exception] exception
        # @return [GRPC::BadStatus]
        #
        def to_grpc_ex exception
          case exception
          when GRPC::BadStatus
            exception
          else
            GRPC::Unknown.new(exception.message)
          end
        end
      end
    end
  end
end
