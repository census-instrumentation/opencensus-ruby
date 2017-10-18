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

describe OpenCensus::Trace::Trace do
  describe ".initialize" do
    it "uses the trace id passed in" do
      trace = OpenCensus::Trace::Trace.new trace_id: "abcdef"
      trace.trace_id.must_equal "abcdef"
    end

    it "generates a random trace span" do
      trace = OpenCensus::Trace::Trace.new
      trace.trace_id.must_match(/[a-z0-9]{32}/)
    end
  end

  describe ".in_span" do
    let(:trace) { OpenCensus::Trace::Trace.new }

    it "returns the value of the provided block" do
      result = trace.in_span "value" do |span|
        "some response"
      end
      result.must_equal "some response"
    end

    it "yields the generated span" do
      s = nil
      trace.in_span "value" do |span|
        s = span
      end
      spans = trace.spans
      s.must_equal spans[0]
    end
  end
end
