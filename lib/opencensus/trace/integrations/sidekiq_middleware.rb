# Copyright 2019 OpenCensus Authors
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

require "opencensus/trace/integrations/active_support"

# TODO: add tests for this middleware
module OpenCensus
  module Trace
    module Integrations

      # # Sidekiq integration
      #
      # This is a middleware for Sidekiq applications:
      #
      # * It wraps all jobs in a root span
      # * It exports the captured spans at the end of the job
      #
      # ## Configuration
      #
      # Example:
      # # config/initializers/sidekiq.rb
      #
      # require "opencensus/trace/integrations/sidekiq_middleware"
      # Sidekiq.configure_server do |config|
      #   config.server_middleware do |chain|
      #     chain.add OpenCensus::Trace::Integrations::SidekiqMiddleware
      #   end
      # end
      #
      class SidekiqMiddleware
        ##
        # Create the Sidekiq middleware.
        #
        # @param [#export] exporter The exported used to export captured spans
        #     at the end of the request. Optional: If omitted, uses the exporter
        #     in the current config.
        #
        def initialize exporter: nil
          @exporter = exporter || OpenCensus::Trace.config.exporter

          config = configuration
          @trace_prefix = config.trace_prefix
          @job_attrs = config.job_attrs_for_trace_name
        end

        # @param [Object] worker the worker instance
        # @param [Hash] job the full job payload
        #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
        # @param [String] queue the name of the queue the job was pulled from
        # @yield the next middleware in the chain or worker `perform` method
        # @return [Void]
        def call _worker, job, _queue
          trace_path = [@trace_prefix, job.values_at(*@job_attrs)].join("/")

          # TODO: find a way to give the job data to the sampler
          # Duplicate this class maybe lib/opencensus/trace/formatters/trace_context.rb
          # trace_context: job.slice(*%w(class args queue)),

          # TODO: use a sampler. We need to figure out how to pass job details
          # to the sampler to choose whether or not to sample this run
          unless configuration.sample_proc.call(job)
            yield
            return
          end

          Trace.start_request_trace \
            trace_context: nil,
            same_process_as_parent: false do |span_context|
            begin
              Trace.in_span trace_path do |span|
                start_job span
                yield
              end
            ensure
              @exporter.export span_context.build_contained_spans
            end
          end
        end

        private

        ##
        # @private Get OpenCensus Sidekiq config
        def configuration
          OpenCensus::Trace.config.sidekiq
        end

        ##
        # Configures the root span for this job.
        #
        # @private
        # @param [Google::Cloud::Trace::TraceSpan] span The root span to
        #     configure.
        def start_job span
          span.kind = SpanBuilder::SERVER
          span.put_attribute "http.host", configuration.host_name
        end
      end
    end
  end
end
