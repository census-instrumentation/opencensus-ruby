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

require "opencensus/trace/integrations/rails"

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
      # See OpenCensus::Trace::Integrations::Rails for details on configuration
      # of attribute_namespace to prefix span
      #
      # ### Trace path
      # The Sidekiq middleware also provides a `sidekiq` configuration that
      # supports the following fields:
      #
      # * `enable` defaults to true
      # *  `sample_proc`, defaults to a proc that returns true. Allows you to
      #     test the contents of the Sidekiq job hash to decide if you want to
      #     sample a certain job. If the proc returns true the job will be
      #     sampled.
      # * `trace_prefix` will be prepended to the trace name in the Trace list.
      #     Defaults to 'sidekiq/'
      # * `job_attrs_for_trace_name` used to get attributes from the Sidekiq job hash
      #     to append to the trace name. Defaults to ["class"]. This will allow
      #     you to include job arguments for example, but take care not to
      #     include sensitive data in the trace name
      class SidekiqMiddleware
        OpenCensus::Trace.configure do |c|
          c.add_config! :sidekiq do |sc|
            sc.add_option! :enable, true

            # TODO: remove this when we have a solution that follows the
            # standards of the rest of the gem
            sc.add_option! :sample_proc, ->(_job) { true }
            sc.add_option! :trace_prefix, "sidekiq/"
            sc.add_option! :job_attrs_for_trace_name, %w(class)
          end
        end

        ##
        # Create the Sidekiq middleware.
        #
        # @param [#export] exporter The exported used to export captured spans
        #     at the end of the request. Optional: If omitted, uses the exporter
        #     in the current config.
        #
        def initialize exporter: nil
          config = OpenCensus::Trace.config

          @exporter = exporter || config.exporter

          @trace_prefix = config.sidekiq.trace_prefix
          @job_attrs = config.sidekiq.job_attrs_for_trace_name

          setup_notifications
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
          unless OpenCensus::Trace.config.sidekiq.sample_proc.call(job)
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
        # Initialize notifications
        # @private
        #
        def setup_notifications
          OpenCensus::Trace.configure.notifications.events.each do |type|
            ActiveSupport::Notifications.subscribe(type) do |*args|
              event = ActiveSupport::Notifications::Event.new(*args)
              handle_notification_event event
            end
          end
        end

        ##
        # Add a span based on a notification event.
        # @private
        #
        def handle_notification_event event
          span_context = OpenCensus::Trace.span_context
          if span_context
            ns = OpenCensus::Trace.configure.notifications.attribute_namespace
            span = span_context.start_span event.name, skip_frames: 2
            span.start_time = event.time
            span.end_time = event.end
            event.payload.each do |k, v|
              span.put_attribute "#{ns}#{k}", v.to_s
            end
          end
        end

        # TODO: set project Id and credentials following opencensus doc
        ##
        # Fallback to default configuration values if not defined already
        def init_default_config
          configuration.project_id ||= Google::Cloud::Trace.default_project_id
          configuration.credentials ||= Google::Cloud.configure.credentials
          configuration.capture_stack ||= false
        end

        ##
        # @private Get Google::Cloud::Trace.configure
        def configuration
          Google::Cloud::Trace.configure
        end

        ##
        # Configures the root span for this job.
        #
        # @private
        # @param [Google::Cloud::Trace::TraceSpan] span The root span to
        #     configure.
        def start_job span
          # TODO: tidy up stack trace
          # https://github.com/googleapis/google-cloud-ruby/blob/master/google-cloud-trace/lib/google/cloud/trace/notifications.rb#L92

          span.kind = SpanBuilder::SERVER
          # TODO: use a different configuration key
          span.put_attribute "http.host", Google::Cloud::Trace.configure.host

          # TODO: we need to change the location of this config variable
          span.put_attribute "http.path", Google::Cloud::Trace.configure.http_url

          # TODO: see if we need to upload these values
          # span.name = span_name
          #
          # span.put_attribute "pid", ::Process.pid.to_s
          # span.put_attribute "tid", ::Thread.current.object_id.to_s
          #
          # if capture_stack
          #   Google::Cloud::Trace::LabelKey.set_stack_trace labels,
          #                                                  skip_frames: 3
          # end
          #
        end
      end
    end
  end
end
