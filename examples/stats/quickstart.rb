# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "opencensus"

MiB = 1 << 20
fontend_key = "my.org/keys/frontend"
video_size_measure = OpenCensus::Stats.measure_int(
  name: "my.org/measures/video_size",
  unit: "By",
  description: "size of processed videos"
)
video_size_distribution = OpenCensus::Stats.distribution_aggregation(
  [0.0, 16.0 * MiB, 256.0 * MiB]
)

video_size_view = OpenCensus::Stats.create_view(
  name: "my.org/views/video_size",
  measure: video_size_measure,
  aggregation: video_size_distribution,
  description: "processed video size over time",
  tag_keys: [fontend_key]
)

stats_recorder = OpenCensus::Stats.recorder
stats_recorder.register_view(video_size_view)

tag_map = OpenCensus::Tags::TagMap.new({
  fontend_key => "mobile-ios9.3.5"
})

stats_recorder.record(
  video_size_measure.measurement(25 * MiB),
  tags: tag_map
)

view_data = stats_recorder.view_data video_size_view.name

p view_data.data
