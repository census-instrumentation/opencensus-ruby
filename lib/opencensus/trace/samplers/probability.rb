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
      class Probability
        DEFAULT_RATE = 0.1

        def initialize rate, rng: nil
          if rate > 1 || rate < 0
            raise ArgumentError.new("Invalid rate - must be between 0 and 1.")
          end
          @rate = rate
          @rng = rng || Random.new
        end

        def call opts={}
          span_context = opts[:span_context]
          if span_context
            value = (span_context.trace_id % 0x10000000000000000).to_f /
              0x10000000000000000
          else
            value = @rng.rand
          end
          value <= @rate
        end
      end
    end
  end
end
