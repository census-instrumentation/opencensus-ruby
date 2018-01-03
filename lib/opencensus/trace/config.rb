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

require "opencensus/trace/exporters"
require "opencensus/trace/formatters"
require "opencensus/trace/samplers"

module OpenCensus
  module Trace
    ##
    # The OpenCensus Trace configuration. See Trace#configure for more info.
    #
    Config = Common::Config.new do |config|
      default_sampler =
        Samplers::Probability.new Samplers::Probability::DEFAULT_RATE
      config.add_option! :default_sampler, default_sampler do |value|
        value.respond_to? :call
      end
      default_exporter =
        Exporters::Logger.new ::Logger.new(STDOUT, ::Logger::INFO)
      config.add_option! :exporter, default_exporter do |value|
        value.respond_to? :export
      end
      default_formatter =
        Formatters::TraceContext.new
      config.add_option! :formatter, default_formatter do |value|
        value.respond_to?(:serialize) &&
          value.respond_to?(:deserialize) &&
          value.respond_to?(:header_name) &&
          value.respond_to?(:rack_header_name)
      end
      config.add_option! :default_max_attributes, 32
      config.add_option! :default_max_stack_frames, 32
      config.add_option! :default_max_annotations, 32
      config.add_option! :default_max_message_events, 128
      config.add_option! :default_max_links, 128
      config.add_option! :default_max_string_length, 1024
    end

    class << self
      ##
      # Configure OpenCensus Trace. These configuration fields included
      # parameters governing sampling, span creation, and exporting.
      #
      # Generally, you should configure this once at process initialization,
      # but it can be modified at any time.
      #
      # Example:
      #
      #     OpenCensus::Trace.configure do |config|
      #       config.default_sampler =
      #         OpenCensus::Trace::Samplers::AlwaysSample.new
      #       config.default_max_attributes = 16
      #     end
      #
      # The configuration object is also exposed in the Rails configuration
      # in a Rails application that installs the OpenCensus railtie.
      #
      # Supported fields are:
      #
      # *   `default_sampler` The default sampler to use. Must be a sampler,
      #     an object with a call method that takes a single options hash.
      #     See OpenCensus::Trace::Samplers. The initial value is a Probability
      #     sampler with a default rate.
      # *   `exporter` The exporter to use. Must be an exporter, an object with
      #     an export method that takes an array of Span objects. See
      #     OpenCensus::Trace::Exporters. The initial value is a Logger exporter
      #     that logs to STDOUT.
      # *   `formatter` The trace context propagation formatter to use. Must be
      #     a formatter, an object with serialize, deserialize, header_name,
      #     and rack_header_name methods. See OpenCensus::Trace::Formatter. The
      #     initial value is a TraceContext formatter.
      # *   `default_max_attributes` The maximum number of attributes to add to
      #     a span. Initial value is 32. Use 0 for no maximum.
      # *   `default_max_stack_frames` The maximum number of stack frames to
      #     represent in a span's stack trace. Initial value is 32. Use 0 for
      #     no maximum.
      # *   `default_max_annotations` The maximum number of annotations to add
      #     to a span. Initial value is 32. Use 0 for no maximum.
      # *   `default_max_message_events` The maximum number of message events
      #     to add to a span. Initial value is 128. Use 0 for no maximum.
      # *   `default_max_links` The maximum number of links to add to a span.
      #     Initial value is 128. Use 0 for no maximum.
      # *   `default_max_string_length` The maximum length of string fields.
      #     Initial value is 1024. Use 0 for no maximum.
      #
      def configure
        if block_given?
          yield Config
        else
          Config
        end
      end
    end
  end
end
