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

describe OpenCensus::Trace::Exporters::Multi do
  describe "export" do
    let(:spans) { ["span1", "span2"] }

    it "should delegate to exporters" do
      mock1 = Minitest::Mock.new
      mock1.expect :export, nil, [spans]
      mock2 = Minitest::Mock.new
      mock2.expect :export, nil, [spans]

      exporter = OpenCensus::Trace::Exporters::Multi.new mock1, mock2
      exporter.export spans

      mock1.verify
      mock2.verify
    end

    it "should allow empty" do
      exporter = OpenCensus::Trace::Exporters::Multi.new
      exporter.export spans
    end
  end

  describe "array management" do
    let(:exporter1) { "exporter1" }
    let(:exporter2) { "exporter2" }

    it "allows adding to the multi and retrieving by index" do
      exporter = OpenCensus::Trace::Exporters::Multi.new
      exporter << exporter1
      exporter.push exporter2
      exporter[0].must_equal exporter1
      exporter[1].must_equal exporter2
    end
  end
end
