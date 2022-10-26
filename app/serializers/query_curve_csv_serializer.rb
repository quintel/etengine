# frozen_string_literal: true

# Queries the graph to extract curves and serializes the results as a CSV.
class QueryCurveCSVSerializer
  attr_reader :filename

  def initialize(config, gql, filename)
    @config   = config
    @gql      = gql
    @filename = filename
  end

  def to_csv_rows
    curves = @config.map do |curve_config|
      {
        name: curve_config[:name],
        curve: @gql.future.subquery(curve_config[:query])
      }
    end

    CurvesCSVSerializer.new(curves, @gql.future.graph.year, @filename).to_csv_rows
  end
end
