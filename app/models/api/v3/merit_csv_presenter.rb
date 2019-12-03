# frozen_string_literal: true

module Api
  module V3
    # Creates CSV rows describing merit order production and consumption.
    class MeritCSVPresenter < CurvesCSVPresenter
      private

      def producer_types
        %i[producer flex]
      end

      def consumer_types
        %i[consumer flex]
      end
    end
  end
end
