# frozen_string_literal: true

require "opencensus/tags/formatters/binary"

module OpenCensus
  module Tags
    ##
    # The Formatters module contains several implementations of cross-service
    # context propagation. Each formatter can serialize and deserialize a
    # {OpenCensus::Tags::TagMap} instance.
    #
    module Formatters
    end
  end
end
