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
      # # Rails Integration
      #
      # This Railtie automatically sets up OpenCensus for a Rails server:
      #
      # * It wraps all requests in spans
      # * It wraps common events (ActiveRecord database calls, ActionView
      #   renders, etc) in subspans.
      #
      # TODO: Implement Rails integration
      #
      class Rails < ::Rails::Railtie
        ##
        # The default list of ActiveSupport notification types to include in
        # traces.
        #
        DEFAULT_NOTIFICATIONS = [
          "sql.active_record",
          "render_template.action_view",
          "send_file.action_controller",
          "send_data.action_controller",
          "deliver.action_mailer"
        ].freeze

        initializer "opencensus.trace" do |app|
          # initialize middleware
          app.middleware.insert_before ::Rack::Runtime, RackMiddleware

          # TODO: handle rails configuration
          DEFAULT_NOTIFICATIONS.each do |type|
            ActiveSupport::Notifications.subscribe(type) do |*args|
              # event = ActiveSupport::Notifications::Event.new(*args)
              # TODO: handle event
            end
          end
        end
      end
    end
  end
end
