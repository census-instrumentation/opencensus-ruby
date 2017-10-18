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

describe OpenCensus::Trace do
  before {
    OpenCensus::Context.reset!
    OpenCensus::Trace.start
  }

  describe ".in_span" do
    before {
      OpenCensus::Trace.in_span("main") do |primary|
        OpenCensus::Trace.in_span("child") do |secondary|
          # do something
        end
      end
    }

    let(:spans) { OpenCensus::Trace.spans }

    it "captures spans" do
      spans.count.must_equal 2
    end

    it "captures parent_span_id" do
      spans[1].parent_span_id.must_equal spans[0].span_id
    end

    it "captures span names" do
      spans[0].name.must_equal "main"
    end

    it "captures nested span names" do
      spans[1].name.must_equal "child"
    end
  end
end
