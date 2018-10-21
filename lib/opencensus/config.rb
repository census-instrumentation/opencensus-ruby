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

require "opencensus/common/config"

module OpenCensus
  # The OpenCensus overall configuration.
  @config = Common::Config.new

  class << self
    ##
    # Configure OpenCensus. Most configuration parameters are defined in
    # subconfigurations that live under this main configuration. See, for
    # example, {OpenCensus::Trace.configure}.
    #
    # If the OpenCensus Railtie is installed in a Rails application, the
    # toplevel configuration object is also exposed as `config.opencensus`.
    #
    # Generally, you should configure this once at process initialization,
    # but it can be modified at any time.
    #
    # Example:
    #
    #     OpenCensus.configure do |config|
    #       config.trace.default_sampler =
    #         OpenCensus::Trace::Samplers::RateLimiting.new
    #       config.trace.default_max_attributes = 16
    #     end
    #
    def configure
      if block_given?
        yield @config
      else
        @config
      end
    end

    ##
    # Get the current configuration.
    # @private
    #
    attr_reader :config
  end
end
