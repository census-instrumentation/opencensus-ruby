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
    module Samplers
      ##
      # The Probability sampler uses a random number generator against a
      # configured rate to determine whether or not to sample.
      #
      class Probability
        ##
        # The default sampling probability.
        #
        DEFAULT_RATE = 0.1

        ##
        # Create a sampler for the given probability.
        #
        # @param [Number] rate Probability that we will sample. This value must
        #        be between 0 and 1.
        # @param [#rand] rng The random number generator to use. Default is a
        #        new Random instance.
        #
        def initialize rate, rng: nil
          if rate > 1 || rate < 0
            raise ArgumentError, "Invalid rate - must be between 0 and 1."
          end
          @rate = rate
          @rng = rng || Random.new
        end

        ##
        # Implements the sampler contract. Checks to see whether a sample
        # should be taken at this time.
        #
        # @param [Hash] opts The options to sample with.
        # @option opts [SpanContext] :span_context If provided, the span context
        #         will be used to generate a deterministic value in place of the
        #         pseudo-random number generator.        #
        # @return [boolean] Whether to sample at this time.
        #
        def call opts = {}
          span_context = opts[:span_context]
          return true if span_context && span_context.sampled?
          value =
            if span_context
              (span_context.trace_id.to_i(16) % 0x10000000000000000).to_f /
                0x10000000000000000
            else
              @rng.rand
            end
          value <= @rate
        end
      end
    end
  end
end
