require "test_helper"

describe OpenCensus::Stats::Exemplar do
  describe "create" do
    it "create instance with attachments" do
      value = 100.1
      time = Time.now.utc
      attachments = { "test" => "value" }

      exemplar = OpenCensus::Stats::Exemplar.new(
        value: value,
        time: time,
        attachments: attachments
      )

      exemplar.value.must_equal value
      exemplar.time.must_equal time
      exemplar.attachments.must_equal attachments
    end

    it "attachments can not be nil" do
      value = 100.2
      time = Time.now.utc
      attachments = nil

      proc {
        OpenCensus::Stats::Exemplar.new(
          value: value,
          time: time,
          attachments: attachments
        )
      }.must_raise ArgumentError
    end
  end
end
