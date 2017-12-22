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

require "opencensus/trace/samplers/always_sample"
require "opencensus/trace/samplers/never_sample"
require "opencensus/trace/samplers/probability"
require "opencensus/trace/samplers/max_qps"

module OpenCensus
  module Trace
    ##
    # A sampler determines whether a given request's latency trace should
    # actually be reported. It is usually not necessary to trace every
    # request, especially for an application serving heavy traffic. You may
    # use a sampler to decide, for a given request, whether to report its
    # trace.
    #
    # The OpenCensus specification defines three samplers: AlwaysSample,
    # NeverSample, and Probability. The Ruby implementation also provides a
    # fourth, MaxQPS, based on the Stackdriver library.
    #
    # A sampler is a Proc that takes a hash of environment information and
    # returns a boolean indicating whether or not to sample the current
    # request. Alternately, it could be an object that duck-types the Proc
    # interface by implementing the `call` method. The hash passed to `call`
    # may contain the following keys, all of which are optional. Samplers must
    # adjust their behavior to account for the availability or absence of any
    # environment information:
    #
    # *   `span_context` The SpanContext that created the span being sampled.
    # *   `rack_env` The hash of Rack environment information
    #
    # Applications may set a default sampler in the config. In addition, the
    # sampler may be overridden whenever a span is created.
    #
    module Samplers
    end
  end
end
