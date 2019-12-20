# frozen_string_literal: true

module Api
  module V3
    # Creates a CSV containing the price of a merit order for each hour in the
    # year.
    class MeritPriceCSVPresenter
      def initialize(graph, order)
        @graph = graph
        @order = order
      end

      def to_csv_rows
        # Empty CSV if time-resolved calculations are not enabled.
        unless Qernel::Plugins::Causality.enabled?(@graph)
          return [['Merit order and time-resolved calculation are not ' \
                   'enabled for this scenario']]
        end

        [
          CurvesCSVPresenter.time_column(@graph.year),
          ['Price (Euros)'] + @order.price_curve.to_a
        ].transpose
      end

      def filename
        'electricity_price'
      end
    end
  end
end
