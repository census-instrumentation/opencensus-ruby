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

require "active_support"
require "rails/railtie"
require "opencensus/trace/integrations/rack_middleware"

module OpenCensus
  module Trace
    module Integrations
      ##
      # # Rails Integration
      #
      # This Railtie automatically sets up OpenCensus for a Rails server:
      #
      # *   It wraps all requests in spans, using the `RackMiddleware`
      #     integration.
      # *   It wraps common events (ActiveRecord database calls, ActionView
      #     renders, etc) in subspans.
      #
      # ## Configuration
      #
      # This Railtie exposes the OpenCensus configuration on the `opencensus`
      # key of the Rails configuration. So you can, for example, set:
      #
      #     config.opencensus.trace.default_max_attributes = 64
      #
      # This Railtie also provides a `notifications` configuration that
      # supports the following fields:
      #
      # * `events` An array of strings indicating the events that will
      #   trigger the creation of spans. The default value is
      #   {OpenCensus::Trace::Integrations::Rails::DEFAULT_NOTIFICATION_EVENTS}.
      # * `attribute_namespace` A string that will be prepended to all
      #   attributes copied from the event payload. Defaults to "`rails/`"
      #
      # You can access these in the `notifications` subconfiguration under
      # the trace configuration. For example:
      #
      #     OpenCensus::Trace.config do |config|
      #       config.notifications.attribute_namespace = "myapp/"
      #     end
      #
      # Or, using Rails:
      #
      #     config.opencensus.trace.notifications.attribute_namespace = "myapp/"
      #
      class Rails < ::Rails::Railtie
        ##
        # The ActiveSupport notifications that will be reported as spans by
        # default. To change this list, update the value of the
        # `trace.notifications.events` configuration.
        #
        DEFAULT_NOTIFICATION_EVENTS = [
          "sql.active_record",
          "render_template.action_view",
          "send_file.action_controller",
          "send_data.action_controller",
          "deliver.action_mailer"
        ].freeze

        OpenCensus::Trace.configure do |c|
          c.add_config! :notifications do |rc|
            rc.add_option! :events, DEFAULT_NOTIFICATION_EVENTS.dup
            rc.add_option! :attribute_namespace, "rails/"
          end
        end

        unless config.respond_to? :opencensus
          config.opencensus = OpenCensus.configure
        end

        initializer "opencensus.trace" do |app|
          app.middleware.insert_before ::Rack::Runtime, RackMiddleware
          setup_notifications
        end

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
      end
    end
  end
end
