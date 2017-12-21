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

describe OpenCensus::Trace::Formatters::CloudTrace do
  let(:formatter) { OpenCensus::Trace::Formatters::CloudTrace.new }

  describe "deserialize" do
    it "should return nil on invalid format" do
      data = formatter.deserialize "badvalue"
      data.must_be_nil
    end

    it "should parse a valid format" do
      data = formatter.deserialize "123456789012345678901234567890ab/1234;o=1"
      data.wont_be_nil
      data.trace_id.must_equal "123456789012345678901234567890ab"
      data.span_id.must_equal "00000000000004d2"
      data.trace_options.must_equal 1
    end
  end

  describe "serialize" do
    let(:trace_data) do
      OpenCensus::Trace::SpanContext::TraceData.new(
        "123456789012345678901234567890ab",
        1,
        {},
        {}
      )
    end
    let(:span_context) do
      OpenCensus::Trace::SpanContext.new trace_data, nil, "00000000000004d2"
    end

    it "should serialize a SpanContext object" do
      header = formatter.serialize span_context
      header.must_equal "123456789012345678901234567890ab/1234;o=1"
    end
  end
end
