# frozen_string_literal: true

# Creates a CSV containing the price of a carrier for each hour in the year.
class CarrierPriceCSVSerializer
  def initialize(carrier, year)
    @carrier = carrier
    @year = year
  end

  def to_csv_rows
    [
      CurvesCSVSerializer.time_column(@year),
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
