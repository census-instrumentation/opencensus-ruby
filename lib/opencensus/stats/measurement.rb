# frozen_string_literal: true


module OpenCensus
  module Stats
    # Struct that holds measurement value
    # @attr [Measure] Measure details
    # @attr [Integer, Float] Value of the measurement
    Measurement = Struct.new(:measure, :value)
  end
end
