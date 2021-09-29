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

    [headers, *data]
  end

  private

  def headers
    [
      'Production (MW)',
      'Demand (MW)',
      'Buffering and time-shifting (MW)',
      'Deficit (MW)'
    ]
  end

  def data
    curve(:production).zip(
      curve(:demand),
      curve(:surplus),
      curve(:deficit)
    )
  end

  def curve(type)
    Merit::CurveTools.add_curves(
      @groups.map { |group| summary(group).public_send(type) }
    )
  end

  def summary(group)
    @graph.plugin(:time_resolve).fever.summary(group)
  end
end
