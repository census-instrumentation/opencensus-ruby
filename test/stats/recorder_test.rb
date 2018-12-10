require "test_helper"

describe OpenCensus::Stats::Recorder do
  after{
    OpenCensus::Tags.unset_tags_context
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

  it "create with default properties" do
    recorder = OpenCensus::Stats::Recorder.new

    recorder.views.must_be_empty
    recorder.exporters.must_be_empty
    recorder.measures.must_be_empty
    recorder.measure_views_data.must_be_empty
  end

  describe "register_view" do
    it "register new view" do
      recorder =  OpenCensus::Stats::Recorder.new

      recorder.register_view view
      recorder.views.length.must_equal 1
      recorder.views[view.name].must_equal view
      recorder.measures.length.must_equal 1
      recorder.measures[measure.name].must_equal measure
      recorder.measure_views_data.length.must_equal 1
      recorder.measure_views_data[measure.name].length.must_equal 1
      recorder.measure_views_data[measure.name].first.must_be_instance_of OpenCensus::Stats::ViewData
    end

    it "can not register same name view" do
      recorder =  OpenCensus::Stats::Recorder.new

      recorder.register_view view
      recorder.views.length.must_equal 1

      view1 = OpenCensus::Stats::View.new(
        name: "test.view",
        measure: measure,
        aggregation: OpenCensus::Stats::Aggregation.new(:count),
        description: "View for count",
        columns: ["service-1"]
      )

      recorder.register_view view1
      recorder.views.length.must_equal 1
      recorder.views[view.name].must_equal view
    end

    it "register multiple views"  do
      recorder =  OpenCensus::Stats::Recorder.new
      recorder.register_view view

      view1 = OpenCensus::Stats::View.new(
        name: "test.view1",
        measure: measure,
        aggregation: OpenCensus::Stats::Aggregation.new(:count),
        description: "View for count",
        columns: ["service-1"]
      )

      recorder.register_view view1
      recorder.views.length.must_equal 2
    end
  end

  describe "record measurements" do
    it "single measurement" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      recorder.record measure.measurement(10), tags: tag_map
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 1
    end

    it "multiple measurement" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      recorder.record measure.measurement(10), measure.measurement(20), tags: tag_map
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 1
    end

    it "reject negative measurement value" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      recorder.record measure.measurement(-1), tags: tag_map
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 0
    end

    it "reject measurement if measure is not present for a given view" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      measure1 = OpenCensus::Stats::Measure.new(
        name: "latency-1",
        unit: "ms",
        type: :int,
        description: "latency desc"
      )
      recorder.record measure1.measurement(1), tags: tag_map
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 0
    end

    it "record measurement against tags global context" do
      OpenCensus::Tags.tags_context = OpenCensus::Tags::TagMap.new(
        "frontend" => "android-1.0.1"
      )

      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      recorder.record measure.measurement(1)
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 1
      view_data.data.key?(["android-1.0.1"]).must_equal true
    end
  end

  describe "clear_stats" do
    it "reacord and clear stats" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      recorder.record measure.measurement(10), tags: tag_map
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 1

      recorder.clear_stats

      recorder.measure_views_data.values.each do |views_data|
        views_data.each do |view_data|
          view_data.data.must_be_empty
        end
      end
    end
  end

  describe "get view data" do
    it "record measurement and get view data" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view
      recorder.record measure.measurement(1), tags: tag_map
      view_data = recorder.view_data view.name
      view_data.must_be_instance_of OpenCensus::Stats::ViewData
    end

    it "return nil for non exists view" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view
      recorder.record measure.measurement(1), tags: tag_map
      view_data = recorder.view_data "non-exists-view"
      view_data.must_be_nil
    end
  end

  describe "exporters" do
    let(:sample_exporter) {
      Struct.new(:name).new(name: "test")
    }

    it "register exporter" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_exporter sample_exporter
      recorder.exporters.length.must_equal 1
    end

    it "un-register exporter" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_exporter sample_exporter

      recorder.unregister_exporter sample_exporter
      recorder.exporters.must_be_empty
    end
  end
end
