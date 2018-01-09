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

require "opencensus/trace/integrations/rails"

describe OpenCensus::Trace::Integrations::Rails do
  describe "#setup_notifications" do
    let(:railtie) { OpenCensus::Trace::Integrations::Rails.instance }
    after {
      ActiveSupport::Notifications.notifier = ActiveSupport::Notifications::Fanout.new
      OpenCensus::Trace.unset_span_context
    }

    it "creates spans for sql notifications" do
      railtie.setup_notifications
      OpenCensus::Trace.start_request_trace
      ActiveSupport::Notifications.instrument("sql.active_record", query: "hello") do
      end
      spans = OpenCensus::Trace.span_context.build_contained_spans
      spans.size.must_equal 1
      span = spans.first
      span.name.value.must_equal "sql.active_record"
      span.attributes.size.must_equal 1
      span.attributes["rails/query"].value.must_equal "hello"
    end
  end
end
