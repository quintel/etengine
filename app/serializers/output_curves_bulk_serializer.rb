# frozen_string_literal: true

# Serializes specified output curves for a scenario as a single CSV with each curve as a column.
class OutputCurvesBulkSerializer

  def initialize(scenario, curve_types)
    @scenario = scenario
    @curve_types = curve_types || []
  end

  def as_csv
    return empty_csv if @curve_types.empty?

    curves = {}
    @curve_types.each do |curve_type|
      csv = QueryCurveCsvSerializer.new(@scenario, curve_type).as_csv
      lines = csv.lines.map(&:strip).reject(&:empty?)
      lines.shift if lines.first && lines.first.match?(/[^\d.\-eE]/)
      curves[curve_type] = lines
    rescue
      curves[curve_type] = []
    end

    max_len = curves.values.map(&:length).max || 0
    require 'csv'
    CSV.generate do |csv|
      csv << curves.keys
      (0...max_len).each do |i|
        csv << curves.keys.map { |k| curves[k][i] }
      end
    end
  end

  private

  def empty_csv
    require 'csv'
    CSV.generate { |csv| csv << [] }
  end
end
