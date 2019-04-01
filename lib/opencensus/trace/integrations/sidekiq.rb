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

require "opencensus/trace/integrations/active_support"

module OpenCensus
  module Trace
    module Integrations
      ##
      # # Sidekiq Integration
      #
      # This class automatically sets up OpenCensus for Sidekiq:
      #
      # *   It wraps all requests in spans, using the `SidekiqkMiddleware`
      #     integration.
      # *   It wraps common events (ActiveRecord database calls, ActionView
      #     renders, etc) in subspans.
      #
      # ## Configuration
      # See the OpenCensus::Trace::Integrations::SidekiqMiddleware documentation
      # for information
      # See OpenCensus::Trace::Integrations::Rails for details on configuration
      # of attribute_namespace to prefix span
      #
      # ### Configuring ActiveSupport Notifications
      # See OpenCensus::Trace::Integrations::ActiveSupport for information on
      # ActiveSupport notifications
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
      # * `job_attrs_for_trace_name` used to get attributes from the Sidekiq job
      #     hash to append to the trace name. Defaults to ["class"]. This will
      #     allow you to include job arguments for example, but take care not to
      #     include sensitive data in the trace name
      class Sidekiq
        OpenCensus::Trace.configure do |c|
          c.add_config! :sidekiq do |sc|
            sc.add_option! :enable, true

            # TODO: remove this when we have a solution that follows the
            # standards of the rest of the gem
            sc.add_option! :sample_proc, ->(_job) { true }
            sc.add_option! :trace_prefix, "sidekiq/"
            sc.add_option! :job_attrs_for_trace_name, %w[class]
            sc.add_option! :host_name, ""
          end
        end
      end
    end
  end
end
