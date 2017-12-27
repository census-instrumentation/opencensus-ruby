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

require "logger"

module OpenCensus
  module Trace
    module Exporters
      ##
      # The Logger exporter exports captured spans to a standard Ruby Logger
      # interface.
      #
      class Logger
        ##
        # Create a new Logger exporter
        #
        # @param [#log] logger The logger to write to.
        # @param [Symbol] level The log level. This should be a log level
        #        defined by {https://ruby-doc.org/stdlib-2.5.0/libdoc/logger/rdoc/Logger.html Logger Standard Library}.
        #
        def initialize logger, level: ::Logger::INFO
          @logger = logger
          @level = level
        end

        ##
        # Export the captured spans to the configured logger.
        #
        # @param [Array<Span>] spans The captured spans.
        # @return [Boolean]
        #
        def export spans
          logger.log @level, spans.to_json
        end
      end
    end
  end
end
