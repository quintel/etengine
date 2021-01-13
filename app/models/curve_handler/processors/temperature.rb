# frozen_string_literal: true

module CurveHandler
  module Processors
    # Handles uploaded temperature curves.
    class Temperature < Generic
      def self.serializer
        CustomPriceCurveSerializer
      end
    end
  end
end
