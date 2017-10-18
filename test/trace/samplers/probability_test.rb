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

require "test_helper"

describe OpenCensus::Trace::Samplers::Probability do
  describe ".call" do
    it "should return true if rng < rate" do
      rng = Random.new
      rng.stub :rand, 0.2 do
        sampler = OpenCensus::Trace::Samplers::Probability.new(0.5, rng: rng)
        sampler.call.must_equal true
      end
    end

    it "should return true if rng == rate" do
      rng = Random.new
      rng.stub :rand, 0.5 do
        sampler = OpenCensus::Trace::Samplers::Probability.new(0.5, rng: rng)
        sampler.call.must_equal true
      end
    end

    it "should return false if rng < rate" do
      rng = Random.new
      rng.stub :rand, 0.7 do
        sampler = OpenCensus::Trace::Samplers::Probability.new(0.5, rng: rng)
        sampler.call.must_equal false
      end
    end

    describe "with 1.0 rate" do
      let(:sampler) { OpenCensus::Trace::Samplers::Probability.new 1.0 }

      it "should always return true" do
        sampler.call.must_equal true
      end
    end

    describe "with 0.0 rate" do
      let(:sampler) { OpenCensus::Trace::Samplers::Probability.new 0.0 }

      it "should always return false" do
        sampler.call.must_equal false
      end
    end
  end
end
