# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "opencensus"
require 'pp'

MIB = 1 << 20
frontend_key = "my.org/keys/frontend"
video_size_measure = OpenCensus::Stats.create_measure_int(
  name: "my.org/measures/video_size",
  unit: "By",
  description: "size of processed videos"
)
video_size_distribution = OpenCensus::Stats.create_distribution_aggregation(
  [0.0, 16.0 * MIB, 256.0 * MIB]
)

# You can either create, and then register the view. Or use
# create_and_register_view to register it to the global thingy.
video_size_view = OpenCensus::Stats::View.new(
  name: "my.org/views/video_size",
  measure: video_size_measure,
  aggregation: video_size_distribution,
  description: "processed video size over time",
  columns: [frontend_key]
)

stats_recorder = OpenCensus::Stats::Recorder.new()
stats_recorder.register_view(video_size_view)

# setup up our in-context tags, and record some measurements
tag_map_ios = OpenCensus::Tags::TagMap.new(frontend_key => "mobile-ios9.3.5")
stats_recorder.record(
  video_size_measure.create_measurement(value: 10 * MIB, tags: tag_map_ios),
  video_size_measure.create_measurement(value: 11 * MIB, tags: tag_map_ios),
  video_size_measure.create_measurement(value: 12 * MIB, tags: tag_map_ios),
  video_size_measure.create_measurement(value: 13 * MIB, tags: tag_map_ios),
  video_size_measure.create_measurement(value: 14 * MIB, tags: tag_map_ios)
)

# Another context's data
tag_map_osx = OpenCensus::Tags::TagMap.new(frontend_key => "desktop-osx10.14.4")
stats_recorder.record(
  video_size_measure.create_measurement(value: 20 * MIB, tags: tag_map_osx),
  video_size_measure.create_measurement(value: 21 * MIB, tags: tag_map_osx),
  video_size_measure.create_measurement(value: 22 * MIB, tags: tag_map_osx),
  video_size_measure.create_measurement(value: 23 * MIB, tags: tag_map_osx),
  video_size_measure.create_measurement(value: 24 * MIB, tags: tag_map_osx),
)

view_data = stats_recorder.view_data video_size_view.name

pp view_data.data

# I can't figure out how to make the exporter work
log_exporter = OpenCensus::Stats::Exporters::Logger.new(Logger.new(STDOUT))
log_exporter.export(view_data.data)
