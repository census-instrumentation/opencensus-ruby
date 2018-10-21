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


##
# OpenCensus is a vendor-agnostic single distribution of libraries to provide
# metrics collection and tracing for your services. See https://opencensus.io/
# for general information on OpenCensus.
#
# The OpenCensus module provides a namespace for the Ruby implementation of
# OpenCensus, including the core libraries for OpenCensus metrics and tracing.
#
module OpenCensus
end

require "opencensus/common"
require "opencensus/config"
require "opencensus/context"
require "opencensus/stats"
require "opencensus/tags"
require "opencensus/trace"
require "opencensus/version"
