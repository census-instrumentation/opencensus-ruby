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

require "opencensus/trace/formatters/binary"
require "opencensus/trace/formatters/cloud_trace"
require "opencensus/trace/formatters/trace_context"

module OpenCensus
  module Trace
    ##
    # The Formatters module contains several implementations of cross-service
    # SpanContext propagation. Each formatter can serialize and deserialize a
    # SpanContext instance.
    #
    module Formatters
      ## The default context formatter
      DEFAULT = TraceContext.new

      ##
      # Internal struct that holds parsed trace context data.
      #
      # @private
      #
      TraceContextData = Struct.new :trace_id, :span_id, :trace_options
    end
  end
end
