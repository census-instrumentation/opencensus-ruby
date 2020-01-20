# frozen_string_literal: true

# Copyright 2019 OpenCensus Authors
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

require "opencensus/tags/formatters/binary"

module OpenCensus
  module Tags
    ##
    # The Formatters module contains several implementations of cross-service
    # context propagation. Each formatter can serialize and deserialize a
    # {OpenCensus::Tags::TagMap} instance.
    #
    module Formatters
    end
  end
end
