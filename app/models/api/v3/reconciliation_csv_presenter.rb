# frozen_string_literal: true

module Api
  module V3
    # Creates CSV rows describing hydrogen production.
    class ReconciliationCSVPresenter < CurvesCSVPresenter
      private

      def producer_types
        %i[producer import storage]
      end

      def consumer_types
        %i[consumer export storage]
      end
    end
  end
end
