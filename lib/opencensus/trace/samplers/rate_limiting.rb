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

require "monitor"

module OpenCensus
  module Trace
    module Samplers
      ##
      # The RateLimiting sampler delays a minimum amount of time between each
      # sample, enforcing a maximum QPS across traces that use this sampler.
      #
      class RateLimiting
        ##
        # Default rate in samples per second.
        #
        DEFAULT_RATE = 0.1

        ##
        # Create a sampler for the given QPS.
        #
        # @param [Number] qps Samples per second. Default is {DEFAULT_RATE}.
        # @param [#rand] rng The random number generator to use. Default is a
        #     new Random instance.
        # @param [#now] time_class The time class to use. Default is Time.
        #     Generally used for testing.
        #
        def initialize qps = DEFAULT_RATE, rng: nil, time_class: nil
          @qps = qps
          @time_class = time_class || Time
          @rng = rng || Random.new
          @last_time = @time_class.now.to_f
          @lock = Monitor.new
        end

        ##
        # Implements the sampler contract. Checks to see whether a sample
        # should be taken at this time.
        #
        # @param [Hash] opts The options to sample with.
        # @option opts [SpanContext] :span_context If provided, the span context
        #         will be checked and the parent's sampling decision will be
        #         propagated if the parent was sampled.
        # @return [boolean] Whether to sample at this time.
        #
        def call opts = {}
          span_context = opts[:span_context]
          return true if span_context && span_context.sampled?
          @lock.synchronize do
            time = @time_class.now.to_f
            elapsed = time - @last_time
            @last_time = time
            @rng.rand <= elapsed * @qps
          end
        end
      end

      # MaxQPS is an older, deprecated name for the RateLimiting sampler.
      MaxQPS = RateLimiting
    end
  end
end
