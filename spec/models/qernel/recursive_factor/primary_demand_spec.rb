# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::RecursiveFactor::PrimaryDemand do
  let(:middle_output_conversion) { 1.0 }

  # Create a graph:
  #
  # [Left] <- [Middle] <- [Right]
  let(:left) do
    Qernel::Node.new(key: :left, graph_name: nil).with(demand: 100.0 * middle_output_conversion)
  end

  let(:middle) do
    Qernel::Node.new(key: :middle, graph_name: nil).with(demand: 100.0)
  end

  let(:right) do
    Qernel::Node
      .new(key: :right, graph_name: nil, groups: [:primary_energy_demand])
      .with(demand: 100.0)
  end

  let(:gas) { Qernel::Carrier.new(key: :natural_gas).with({}) }

  def create_edge(left, right, carrier, demand, rgt_conversion = 1.0)
    left.add_slot(Qernel::Slot.new(nil, left, carrier, :input).with(conversion: 1.0))
    right.add_slot(Qernel::Slot.new(nil, right, carrier, :output).with(conversion: rgt_conversion))

    edge = Qernel::Edge.new(
      "#{left.key} <- #{right.key} @ #{carrier.key}", left, right, carrier, :flexible, true
    )

    edge.with(value: demand)
    edge.query.with(value: demand)
    edge
  end

  before do
    create_edge(left, middle, gas, 100.0 * middle_output_conversion, middle_output_conversion)
    create_edge(middle, right, gas, 100.0, 1.0)
  end

  context 'when energy flows right-to-left with no shares or conversions' do
    it 'has primary_demand of 100' do
      expect(left.query.primary_demand).to eq(100.0)
    end
  end

  context 'when energy flows right-to-left with an output conversion of 2.0' do
    let(:middle_output_conversion) { 2.0 }

    it 'has primary_demand of 100' do
      expect(left.query.primary_demand).to eq(100.0)
    end
  end

  context 'when energy flows right-to-left with an output conversion of 0.5' do
    let(:middle_output_conversion) { 0.5 }

    it 'has primary_demand of 50' do
      expect(left.query.primary_demand).to eq(50.0)
    end
  end
end
