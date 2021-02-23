# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::RecursiveFactor::PrimaryCo2 do
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
    Qernel::Node.new(key: :right, graph_name: nil, groups: [:primary_energy_demand])
      .with(demand: 100.0, sustainability_share: 0.25)
  end

  let(:gas) { Qernel::Carrier.new(key: :natural_gas).with({ co2_conversion_per_mj: 0.5 }) }

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
    it 'has primary_co2_emission of 50' do
      expect(left.query.primary_co2_emission).to eq(50)
    end

    it 'has primary_demand_of_sustainable of 25' do
      expect(left.query.primary_demand_of_sustainable).to eq(25)
    end

    it 'has primary_demand_of_fossil of 100' do
      expect(left.query.primary_demand_of_fossil).to eq(75)
    end

    it 'has sustainability_share of 0.5' do
      expect(left.query.sustainability_share).to eq(0.25)
    end
  end

  context 'when energy flows right-to-left with an output conversion of 2.0' do
    let(:middle_output_conversion) { 2.0 }

    it 'has primary_co2_emission of 50' do
      expect(left.query.primary_co2_emission).to eq(50)
    end

    it 'has primary_demand_of_sustainable of 25' do
      expect(left.query.primary_demand_of_sustainable).to eq(25)
    end

    it 'has primary_demand_of_fossil of 75' do
      expect(left.query.primary_demand_of_fossil).to eq(75)
    end

    it 'has sustainability_share of 0.5' do
      expect(left.query.sustainability_share).to eq(0.25)
    end
  end

  context 'when energy flows right-to-left with an output conversion of 0.5' do
    let(:middle_output_conversion) { 0.5 }

    it 'has primary_co2_emission of 25' do
      expect(left.query.primary_co2_emission).to eq(25)
    end

    it 'has primary_demand_of_sustainable of 12.5' do
      expect(left.query.primary_demand_of_sustainable).to eq(12.5)
    end

    it 'has primary_demand_of_fossil of 37.5' do
      expect(left.query.primary_demand_of_fossil).to eq(37.5)
    end

    it 'has sustainability_share of 0.25' do
      expect(left.query.sustainability_share).to eq(0.25)
    end
  end
end
