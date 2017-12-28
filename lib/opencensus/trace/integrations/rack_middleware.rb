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
              span_context.in_span get_path(env) do |_span|
                @app.call env
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
      end
    end
  end
end
