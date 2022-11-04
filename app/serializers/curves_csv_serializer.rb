# frozen_string_literal: true

class CurvesCSVSerializer
  attr_reader :filename

  def self.time_column(year)
    # We don't model leap days: 1970 is a safe choice for accurate times in the CSV.
    base_date = Time.utc(1970, 1, 1)

    ['Time'] +
      Array.new(8760) do |i|
        (base_date + i.hours).strftime("#{year}-%m-%d %R")
      end
  end

  def initialize(curves, year, filename)
    @curves = curves
    @year = year
    @filename = filename
  end

  # Public: Creates an array of rows for a CSV file containing the loads of
  # hydrogen producers and consumers.
  #
  # Returns an array of arrays.
  def to_csv_rows
    # Empty CSV if time-resolved calculations are not enabled.
    # unless @adapter.supported?(@graph)
    #   return [['Merit order and time-resolved calculation are not ' \
    #            'enabled for this scenario']]
    # end

    values = [self.class.time_column(@year)]
    empty_curve = [0] * 8760

    @curves.each do |config|
      if config[:curve].blank?
        values.push([config[:name], empty_curve].flatten)
      else
        values.push([config[:name], config[:curve]].flatten)
      end
    end

    values.transpose
  end

  def as_csv
    CSV.generate do |csv|
      to_csv_rows.each { |row| csv << row }
    end
  end
end
