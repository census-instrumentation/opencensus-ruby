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

describe OpenCensus::Trace::Samplers::RateLimiting do
  let(:start_time) { ::Time.at 10000000.0 }
  let(:time_200ms) { ::Time.at 10000000.2 }
  let(:time_400ms) { ::Time.at 10000000.4 }
  let(:env) { {} }

  describe ".call" do
    it "returns true if rng < elapsed" do
      rng = TestRandom.new [0.1]
      time_class = TestTimeClass.new [start_time, time_200ms]
      sampler = OpenCensus::Trace::Samplers::RateLimiting.new \
        1.0, rng: rng, time_class: time_class
      sampler.call.must_equal true
    end

    it "returns false if rng > elapsed" do
      rng = TestRandom.new [0.3]
      time_class = TestTimeClass.new [start_time, time_200ms]
      sampler = OpenCensus::Trace::Samplers::RateLimiting.new \
        1.0, rng: rng, time_class: time_class
      sampler.call.must_equal false
    end

    it "keeps track of last time" do
      rng = TestRandom.new [0.1, 0.3]
      time_class = TestTimeClass.new [start_time, time_200ms, time_400ms]
      sampler = OpenCensus::Trace::Samplers::RateLimiting.new \
        1.0, rng: rng, time_class: time_class
      sampler.call.must_equal true
      sampler.call.must_equal false
    end

    it "returns true if span context was sampled" do
      rng = TestRandom.new [0.3]
      time_class = TestTimeClass.new [start_time, time_200ms]
      sampler = OpenCensus::Trace::Samplers::RateLimiting.new \
        1.0, rng: rng, time_class: time_class
      trace_context = OpenCensus::Trace::TraceContextData.new "1", "2", 1
      span_context = OpenCensus::Trace::SpanContext.create_root \
        trace_context: trace_context
      sampler.call(span_context: span_context).must_equal true
    end
  end
end
