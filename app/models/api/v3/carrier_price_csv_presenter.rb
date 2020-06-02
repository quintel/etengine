# frozen_string_literal: true

module Api
  module V3
    # Creates a CSV containing the price of a carrier for each hour in the year.
    class CarrierPriceCSVPresenter
      def initialize(carrier, year)
        @carrier = carrier
        @year = year
      end

      def to_csv_rows
        [
          CurvesCSVPresenter.time_column(@year),
          ['Price (Euros)'] + @carrier.cost_curve
        ].transpose
      end

      def filename
        "#{@carrier.key}_price"
      end

      def as_json(*)
        { curve: @carrier.cost_curve.join("\n") }
      end
    end
  end
end
