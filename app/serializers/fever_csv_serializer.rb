# frozen_string_literal: true

# Creates CSV rows describing heat demand and supply for one or more fever groups.
class FeverCSVSerializer
  attr_reader :filename
  def initialize(graph, groups, filename)
    @graph = graph
    @groups = groups.map(&:to_sym)
    @filename = filename.freeze
  end

  def to_csv_rows
    # Empty CSV if time-resolved calculations are not enabled.
    unless @graph.plugin(:time_resolve)&.fever
      return [['Merit order and time-resolved calculation are not ' \
                'enabled for this scenario']]
    end

    data
  end

  private

  def columns_for(node, summary)
    [
      demand_column_for(node, summary),
      production_column_for(node, summary)
    ]
  end

  def safe_curve(curve)
    curve.empty? ? [0.0] * 8760 : curve
  end

  def demand_column_for(node, summary)
    case node.fever.type
    when :consumer
      ["#{node.key}.input.demand (MW)"] +
        safe_curve(summary.total_demand_curve_for_consumer(node.key))
    when :producer
      ["#{node.key}.output.demand (MW)"] +
        safe_curve(summary.total_demand_curve_for_producer(node.key))
    end
  end

  def production_column_for(node, summary)
    case node.fever.type
    when :consumer
      ["#{node.key}.input.production (MW)"] +
        safe_curve(summary.total_production_curve_for_consumer(node.key))
    when :producer
      ["#{node.key}.output.production (MW)"] +
        safe_curve(summary.total_production_curve_for_producer(node.key))
    end
  end

  def data
    @groups.flat_map do |group|
      summary = summary(group)
      summary.nodes.flat_map { |node| columns_for(node, summary) }
    end.transpose
  end

  def summary(group)
    @graph.plugin(:time_resolve).fever.summary(group)
  end
end
