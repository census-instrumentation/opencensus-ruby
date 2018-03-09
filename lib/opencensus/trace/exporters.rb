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

require "opencensus/trace/exporters/logger"
require "opencensus/trace/exporters/multi"

module OpenCensus
  module Trace
    ##
    # The Exporters module provides integrations for exporting collected trace
    # spans to an external or local service. Exporter classes may be put inside
    # this module, but are not required to be located here.
    #
    # An exporter is an object that must respond to the following method:
    #
    #     def export(spans)
    #
    # Where `spans` is an array of {OpenCensus::Trace::Span} objects to export.
    # The method _must_ tolerate any number of spans in the `spans` array,
    # including an empty array.
    #
    # The method return value is not defined.
    #
    # The exporter object may interpret the `export` message in whatever way it
    # deems appropriate. For example, it may write the data to a log file, it
    # may transmit it to a monitoring service, or it may do nothing at all.
    # An exporter may also queue the request for later asynchronous processing,
    # and indeed this is recommended if the export involves time consuming
    # operations such as remote API calls.
    #
    module Exporters
    end
  end
end
