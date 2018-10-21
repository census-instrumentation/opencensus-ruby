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
require "json"

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
        # @param [Integer] level The log level. This should be a log level
        #        defined by the Logger standard library. Default is
        #        `::Logger::INFO`.
        #
        def initialize logger, level: ::Logger::INFO
          @logger = logger
          @level = level
        end

        ##
        # Export the captured spans to the configured logger.
        #
        # @param [Array<Span>] spans The captured spans.
        #
        def export spans
          @logger.log @level, spans.map { |span| format_span(span) }.to_json
          nil
        end

        private

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize

        def format_span span
          {
            name: format_value(span.name),
            kind: span.kind,
            trace_id: span.trace_id,
            span_id: span.span_id,
            parent_span_id: span.parent_span_id,
            start_time: span.start_time,
            end_time: span.end_time,
            attributes: format_attributes(span.attributes),
            dropped_attributes_count: span.dropped_attributes_count,
            stack_trace: span.stack_trace,
            dropped_frames_count: span.dropped_frames_count,
            stack_trace_hash_id: span.stack_trace_hash_id,
            time_events: span.time_events.map { |te| format_time_event(te) },
            dropped_annotations_count: span.dropped_annotations_count,
            dropped_message_events_count: span.dropped_message_events_count,
            links: span.links.map { |link| format_link(link) },
            dropped_links_count: span.dropped_links_count,
            status: format_status(span.status),
            same_process_as_parent_span: span.same_process_as_parent_span,
            child_span_count: span.child_span_count
          }
        end

        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        def format_time_event time_event
          case time_event
          when Annotation
            format_annotation time_event
          when MessageEvent
            format_message_event time_event
          end
        end

        def format_annotation annotation
          {
            description: format_value(annotation.description),
            attributes: format_attributes(annotation.attributes),
            dropped_attributes_count: annotation.dropped_attributes_count,
            time: annotation.time
          }
        end

        def format_message_event message_event
          {
            type: message_event.type,
            id: message_event.id,
            uncompressed_size: message_event.uncompressed_size,
            compressed_size: message_event.compressed_size,
            time: message_event.time
          }
        end

        def format_link link
          {
            trace_id: link.trace_id,
            span_id: link.span_id,
            type: link.type,
            attributes: format_attributes(link.attributes),
            dropped_attributes_count: link.dropped_attributes_count
          }
        end

        def format_status status
          return nil if status.nil?

          {
            code: status.code,
            message: status.message
          }
        end

        def format_attributes attrs
          result = {}
          attrs.each do |k, v|
            result[k] = format_value v
          end
          result
        end

        def format_value value
          case value
          when String, Integer, true, false
            value
          when TruncatableString
            if value.truncated_byte_count.zero?
              value.value
            else
              {
                value: value.value,
                truncated_byte_count: value.truncated_byte_count
              }
            end
          else
            nil
          end
        end
      end
    end
  end
end
