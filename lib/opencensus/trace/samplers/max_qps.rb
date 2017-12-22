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
      # The MaxQPS sampler delays a minimum amount of time between each sample,
      # enforcing a maximum QPS across traces that use this sampler.
      #
      class MaxQPS
        ##
        # Create a sampler for the given QPS.
        #
        # @param [Number] qps Samples per second. Default is 0.1.
        #
        def initialize qps = 0.1
          @delay_secs = 1.0 / qps
          @last_time = ::Time.now.to_f - @delay_secs
        end

        ##
        # Implements the sampler contract. Checks to see whether a sample
        # should be taken at this time.
        #
        # @return [boolean] Whether to sample at this time.
        #
        def call _opts = {}
          time = ::Time.now.to_f
          delays = (time - @last_time) / @delay_secs
          if delays >= 2.0
            @last_time = time - @delay_secs
            true
          elsif delays >= 1.0
            @last_time += @delay_secs
            true
          else
            false
          end
        end
      end
    end
  end
end
