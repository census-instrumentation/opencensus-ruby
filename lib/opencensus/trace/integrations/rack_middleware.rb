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

module OpenCensus
  module Trace
    module Integrations
      ##
      # This Rack middleware implementation manages the trace context and
      # captures a trace for this request. It is also responsible for exporting
      # the captured spans at the end of the request.
      #
      class RackMiddleware
        def initialize app, exporter: nil
          @app = app
          @exporter = exporter || OpenCensus::Trace::Config.exporter
        end

        def call env
          OpenCensus::Trace.start_request_trace rack_env: env do |span_context|
            begin
              span_context.in_span get_path(env) do |span|
                start_request span, env
                @app.call(env).tap do |response|
                  finish_request span, response
                end
              end
            ensure
              @exporter.export span_context.build_contained_spans
            end
          end
        end

        private

        def get_path env
          path = "#{env['SCRIPT_NAME']}#{env['PATH_INFO']}"
          path = "/#{path}" unless path.start_with? "/"
          path
        end

        def get_host env
          env["HTTP_HOST"] || env["SERVER_NAME"]
        end

        def get_url env
          path = get_path env
          host = get_host env
          scheme = env["SERVER_PROTOCOL"]
          query_string = env["QUERY_STRING"].to_s
          url = "#{scheme}://#{host}#{path}"
          url = "#{url}?#{query_string}" unless query_string.empty?
          url
        end

        def start_request span, env
          span.put_attribute "/http/host", get_host(env)
          span.put_attribute "/http/url", get_url(env)
          span.put_attribute "/http/method", env["REQUEST_METHOD"]
          span.put_attribute "/http/client_protocol", env["SERVER_PROTOCOL"]
          span.put_attribute "/http/user_agent", env["HTTP_USER_AGENT"]
          span.put_attribute "/pid", ::Process.pid.to_s
          span.put_attribute "/tid", ::Thread.current.object_id.to_s
        end

        def finish_request span, response
          if response.is_a?(::Array) && response.size == 3
            span.set_status response[0]
            response[1]["Trace-Context"] = span.context.to_trace_context_header
          end
        end
      end
    end
  end
end
