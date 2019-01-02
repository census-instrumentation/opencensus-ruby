# frozen_string_literal: true

require "opencensus/stats/exporters/logger"

module OpenCensus
  module Stats
    ##
    # The Exporters module provides integrations for exporting collected stats
    # spans to an external or local service. Exporter classes may be put inside
    # this module, but are not required to be located here.
    #
    # An exporter is an object that must respond to the following method:
    #
    #     def export(views_data)
    #
    # Where `views_data` is an array of {OpenCensus::Stats::ViewData} objects
    # to export.
    #
    # The method return value is not defined.
    #
    # The exporter object may interpret the `export` message in whatever way it
    # deems appropriate. For example, it may write the data to a log file, it
    # may transmit it to a monitoring service, or it may do nothing at all.
    # An exporter may also queue the request for later asynchronous processing,
    # and indeed this is recommended if the export involves time consuming
    # operations such as remote API calls.
    #
    module Exporters
    end
  end
end
