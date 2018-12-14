require "test_helper"

describe OpenCensus::Stats::Exporters::Logger do
  after{
    OpenCensus::Tags.unset_tags_context
  }

  let(:logger) {
    logger = ::Logger.new STDOUT
    logger.level = ::Logger::INFO
    logger.formatter = -> (_, _, _, msg) { msg }
    logger
  }
  let(:measure){
    OpenCensus::Stats::Measure.new(
      name: "latency",
      unit: "ms",
      type: :int,
      description: "latency desc"
    )
  }
  let(:aggregation){ OpenCensus::Stats::Aggregation.new :sum }
  let(:tag_keys) { ["frontend"]}
  let(:view) {
    OpenCensus::Stats::View.new(
      name: "test.view",
      measure: measure,
      aggregation: aggregation,
      description: "Test view",
      columns: tag_keys
    )
  }
  let(:tag_map) {
    OpenCensus::Tags::TagMap.new(tag_keys.first => "mobile-ios9.3.5")
  }

  describe "export" do
    let(:view_data){
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view
      recorder.record measure.measurement(10), tags: tag_map
      view_data = recorder.view_data view.name
      [view_data]
    }

    it "should emit data for a covered log level" do
      exporter = OpenCensus::Stats::Exporters::Logger.new logger, level: ::Logger::INFO
      out, _err = capture_subprocess_io do
        exporter.export view_data
      end

      out.wont_be_empty
    end

    it "should not emit data for a low log level" do
      exporter = OpenCensus::Stats::Exporters::Logger.new logger, level: ::Logger::DEBUG
      out, _err = capture_subprocess_io do
        exporter.export view_data
      end

      out.must_be_empty
    end
  end
end
