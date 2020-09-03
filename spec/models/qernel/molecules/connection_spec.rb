# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::Molecules::Connection do
  def build_slot(node, carrier, direction, conversion)
    Qernel::Slot.factory(nil, nil, node, carrier, direction).with(conversion: conversion)
  end

  let(:electricity) { Qernel::Carrier.new(key: :electricity).with(co2_conversion_per_mj: 0.0) }
  let(:natural_gas) { Qernel::Carrier.new(key: :natural_gas).with(co2_conversion_per_mj: 0.05) }

  # Demand: 100
  # Inputs: electricity at 75%, natural_gas at 25%
  # Outputs: electricity at 10%, natural_gas at 90%
  let(:source) do
    Qernel::Node.new(key: :molecule_source, graph_name: :energy).tap do |node|
      node.add_slot(build_slot(node, electricity, :input, 0.75))
      node.add_slot(build_slot(node, natural_gas, :input, 0.25))
      node.add_slot(build_slot(node, electricity, :output, 0.1))
      node.add_slot(build_slot(node, natural_gas, :output, 0.9))
      node.with(demand: 100)
    end
  end

  let(:connection) { described_class.new(source, config) }

  context 'when the config specifies to use demand (100) with conversion of 1.0' do
    let(:config) do
      Atlas::NodeAttributes::EnergyToMolecules.new(conversion: 1.0)
    end

    it 'calculates demand of 100' do
      expect(connection.demand).to eq(100)
    end
  end

  context 'when the config specifies to use demand (100) with conversion of 0.2' do
    let(:config) do
      Atlas::NodeAttributes::EnergyToMolecules.new(conversion: 0.2)
    end

    it 'calculates demand of 20' do
      expect(connection.demand).to eq(20)
    end
  end

  context 'when the config specifies to use primary_co2_emission (10) with conversion of 0.5' do
    let(:config) do
      Atlas::NodeAttributes::EnergyToMolecules.new(
        attribute: :primary_co2_emission,
        conversion: 0.5
      )
    end

    before do
      allow(source.query).to receive(:primary_co2_emission).and_return(10.0)
    end

    it 'calculates demand of 5' do
      expect(connection.demand).to eq(5)
    end

    it 'calls the named method on the NodeApi' do
      connection.demand
      expect(source.query).to have_received(:primary_co2_emission)
    end
  end

  context 'when the config specifies to use electricity input (75) with conversion of 1.0' do
    let(:config) do
      Atlas::NodeAttributes::EnergyToMolecules.new(
        direction: :input, conversion: { electricity: 1.0 }
      )
    end

    it 'calculates demand of 75' do
      expect(connection.demand).to eq(75)
    end
  end

  context 'when the config specifies to use electricity input (75) with conversion of 1.0, ' \
          'and natural_gas (25) with a conversion of 0.5' do
    let(:config) do
      Atlas::NodeAttributes::EnergyToMolecules.new(
        direction: :input, conversion: { electricity: 1.0, natural_gas: 0.5 }
      )
    end

    it 'calculates demand of 87.5' do
      expect(connection.demand).to eq(87.5)
    end
  end

  context 'when the config specifies to use electricity output (10) with conversion of 1.0' do
    let(:config) do
      Atlas::NodeAttributes::EnergyToMolecules.new(
        direction: :output, conversion: { electricity: 1.0 }
      )
    end

    it 'calculates demand of 10' do
      expect(connection.demand).to eq(10)
    end
  end

  context 'when the config specifies to use natural_gas input (25) with carrier attribute (0.05)' do
    let(:config) do
      Atlas::NodeAttributes::EnergyToMolecules.new(
        direction: :input, conversion: { natural_gas: 'carrier: co2_conversion_per_mj' }
      )
    end

    it 'calculates demand of 1.25' do
      expect(connection.demand).to eq(1.25)
    end
  end
end
