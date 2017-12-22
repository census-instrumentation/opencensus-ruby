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

describe OpenCensus::Trace::Samplers::MaxQPS do
  let(:start_time) { ::Time.at(12345678) }
  let(:env) { {} }

  def sampler
    ::Time.stub :now, start_time do
      OpenCensus::Trace::Samplers::MaxQPS.new
    end
  end

  describe ".call" do
    it "samples the first time called" do
      sam = OpenCensus::Trace::Samplers::MaxQPS.new
      sam.call(env).must_equal true
    end

    it "doesn't sample when called too soon" do
      sam = sampler
      ::Time.stub :now, start_time - 1 do
        sam.call(env).must_equal false
      end
    end

    it "samples when called after a suitable delay" do
      sam = sampler
      ::Time.stub :now, start_time + 1 do
        sam.call(env).must_equal true
      end
    end

    it "advances last sampling time" do
      sam = sampler
      ::Time.stub :now, start_time + 3 do
        sam.call(env).must_equal true
      end
      ::Time.stub :now, start_time + 9 do
        sam.call(env).must_equal false
      end
      ::Time.stub :now, start_time + 11 do
        sam.call(env).must_equal true
      end
    end

    it "advances last sampling time after a large gap" do
      sam = sampler
      ::Time.stub :now, start_time + 30 do
        sam.call(env).must_equal true
      end
      ::Time.stub :now, start_time + 31 do
        sam.call(env).must_equal true
      end
      ::Time.stub :now, start_time + 32 do
        sam.call(env).must_equal false
      end
    end
  end
end
