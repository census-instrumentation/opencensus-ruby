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

require "faraday"

module OpenCensus
  module Trace
    module Integrations
      class FaradayMiddleware < Faraday::Middleware
        ##
        # Create a Trace span with the HTTP request/response information.
        def call env
          OpenCensus::Trace.in_span "faraday_request" do |span|
            add_request_labels span, env if span

            response = @app.call env

            add_response_labels span, env if span

            response
          end
        end

        protected

        ##
        # @private Set Trace span labels from request object
        def add_request_labels span, env
          labels = span.labels
          labels["/http/method"] = env.method
          labels["/http/url"] = env.url.to_s

          # Only sets request size if request is not sent yet.
          unless env.status
            request_body = env.body || ""
            labels["/rpc/request/size"] = request_body.bytesize.to_s
          end
        end

        ##
        # @private Set Trace span labels from response
        def add_response_labels span, env
          labels = span.labels

          response = env.response
          response_body = response.body || ""
          response_status = response.status
          response_url = response.headers[:location]

          labels["/rpc/response/size"] = response_body.bytesize.to_s
          labels["/rpc/status_code"] = response_status.to_s

          if 300 <= response_status && response_status < 400 && response_url
            labels["http/redirected_url"] = response_url
          end
        end
      end
    end
  end
end
