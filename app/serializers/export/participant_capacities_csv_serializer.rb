# frozen_string_literal: true

# Provides to_csv_rows and filename for capacity exports. When included in a
# CausalityCurvesCSVSerializer subclass, produces a CSV with one row per
# participant (producer or consumer): key, installed_capacity, peak_capacity.
#
# The key matches the column header used in the corresponding hourly curve
# export (e.g. "agriculture_chp_engine_biogas.output (MW)").
module Export::ParticipantCapacitiesCSVSerializer
  def filename
    :"#{@adapter.attribute}_capacities"
  end

  def to_csv_rows
    unless @adapter.supported?(@graph)
      return [['Merit order and time-resolved calculation are not enabled for this scenario']]
    end

    header = %w[key peak_capacity]
    [header, *producer_rows, *consumer_rows]
  end

  private

  def producer_rows
    producers.map { |node| row_for(node, :output) }
  end

  def consumer_rows
    consumers.map { |node| row_for(node, :input) }
  end

  def row_for(node, direction)
    [
      "#{@prefix}#{node.key}.#{direction} (MW)",
      (@adapter.node_curve(node, direction)&.max || 0.0).round(6)
    ]
  end
end
