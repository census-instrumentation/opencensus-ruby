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

module OpenCensus
  module Trace
    ##
    # The Integrations module contains implementations of integrations with
    # popular gems such as Rails and Faraday.
    #
    # Integrations are not loaded by default. To use an integration,
    # require it explicitly. e.g.:
    #
    #     require "opencensus/trace/integrations/rack_middleware"
    #
    module Integrations
    end
  end
end
