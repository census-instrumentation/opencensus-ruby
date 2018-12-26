# frozen_string_literal: true


module OpenCensus
  module Stats
    # Struct that holds measurement value
    Measurement = Struct.new(:measure, :value)
  end
end
