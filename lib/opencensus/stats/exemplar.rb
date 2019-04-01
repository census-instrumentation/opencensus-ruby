# frozen_string_literal: true


module OpenCensus
  module Stats
    ##
    # Exemplars are example points that may be used to annotate aggregated
    # Distribution values. They are metadata that gives information about a
    # particular value added to a Distribution bucket.
    #
    class Exemplar
      # Value of the exemplar point. It determines which bucket the exemplar
      # belongs to
      # @return [Integer,Float]
      attr_reader :value

      # The observation (sampling) time of the above value
      # @return [Time]
      attr_reader :time

      # Contextual information about the example value
      # @return [Hash<String,String>]
      attr_reader :attachments

      # Create instance of the exemplar
      # @param [Integer,Float] value
      # @param [Time] time
      # @param [Hash<String,String>] attachments Attachments are key-value
      #   pairs that describe the context in which the exemplar was recored.
      def initialize value:, time:, attachments:
        @value = value
        @time = time

        raise ArgumentError, "attachments can not be empty" if attachments.nil?

        @attachments = attachments
      end
    end
  end
end
