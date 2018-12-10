require "test_helper"

describe OpenCensus::Stats::View do
  let(:measure){
    OpenCensus::Stats::Measure.new(
      name: "latency",
      unit: "ms",
      type: :int,
      description: "latency desc"
    )
  }
  let(:aggregation){ OpenCensus::Stats::Aggregation.new :sum }
  let(:columns) { ["frontend"]}

  it "create view instance and populate properties" do
    view = OpenCensus::Stats::View.new(
      name: "test.view",
      measure: measure,
      aggregation: aggregation,
      description: "Test view",
      columns: columns
    )

    view.name.must_equal "test.view"
    view.measure.must_equal measure
    view.aggregation.must_equal aggregation
    view.description.must_equal "Test view"
    view.columns.must_equal columns
  end
end
