require "test_helper"

describe OpenCensus::Stats::Recorder do
  before{
    OpenCensus::Tags.unset_tag_map_context
    OpenCensus::Stats::MeasureRegistry.clear
  }
  let(:measure_name) { "latency" }
  let(:measure){
    OpenCensus::Stats.create_measure_int(
      name: measure_name,
      unit: "ms",
      description: "latency desc"
    )
  }
  let(:aggregation){ OpenCensus::Stats::Aggregation::Sum.new }
  let(:tag_key) { "frontend" }
  let(:tag_value) { "mobile.1.0.1" }
  let(:tag_keys) { [tag_key]}
  let(:view) {
    OpenCensus::Stats::View.new(
      name: "test.view",
      measure: measure,
      aggregation: aggregation,
      description: "Test view",
      columns: tag_keys
    )
  }
  let(:tag) {
    OpenCensus::Tags::Tag.new tag_key, tag_value
  }
  let(:tags) {
    OpenCensus::Tags::TagMap.new [tag]
  }

  it "create reacorder with default properties" do
    recorder = OpenCensus::Stats::Recorder.new

    recorder.views.must_be_empty
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
        aggregation: OpenCensus::Stats::Aggregation::Count,
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
        aggregation: OpenCensus::Stats::Aggregation::Count,
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

      measurement = OpenCensus::Stats.create_measurement(
        name: measure_name,
        value: 10,
        tags: tags
      )
      recorder.record measurement
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 1
    end

    it "multiple measurement" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      measurement1 = OpenCensus::Stats.create_measurement(
        name: measure_name,
        value: 10,
        tags: tags
      )
      measurement2 = OpenCensus::Stats.create_measurement(
        name: measure_name,
        value: 20,
        tags: tags
      )
      recorder.record measurement1, measurement2
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 1
    end

    it "reject negative measurement value" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      measurement = OpenCensus::Stats.create_measurement(
        name: measure_name,
        value: -1,
        tags: tags
      )
      recorder.record measurement
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

      recorder.record measure1.create_measurement(value: 1, tags: tags)
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 0
    end

    it "record measurement against tags global context" do
      tag_ctx =  OpenCensus::Tags::TagMap.new
      tag_ctx << OpenCensus::Tags::Tag.new(tag_key, tag_value)
      OpenCensus::Tags.tag_map_context = tag_ctx

      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      measurement = OpenCensus::Stats.create_measurement(
        name: measure_name,
        value: 1
      )
      recorder.record measurement
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 1
      view_data.data.key?([tag_value]).must_equal true
    end
  end

  describe "clear_stats" do
    it "reacord and clear stats" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view

      recorder.record measure.create_measurement(value: 10, tags: tags)
      view_data = recorder.view_data view.name
      view_data.data.length.must_equal 1

      recorder.clear_stats

      recorder.measure_views_data.values.each do |views_data|
        views_data.each do |vd|
          vd.data.must_be_empty
        end
      end
    end
  end

  describe "get view data" do
    it "record measurement and get view data" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view
      recorder.record measure.create_measurement(value: 1, tags: tags)
      view_data = recorder.view_data view.name
      view_data.must_be_instance_of OpenCensus::Stats::ViewData
    end

    it "return nil for non exists view" do
      recorder = OpenCensus::Stats::Recorder.new
      recorder.register_view view
      recorder.record measure.create_measurement(value: 1, tags: tags)
      view_data = recorder.view_data "non-exists-view"
      view_data.must_be_nil
    end
  end
end
