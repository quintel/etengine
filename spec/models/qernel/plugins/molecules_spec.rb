# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::Plugins::Molecules do
  let(:conversion_attributes) { { source: :foo } }

  let(:graph) do
    Scenario.default.gql do |gql|
      node = gql.future.graph.plugin(:molecules).molecule_graph.node(:m_left)

      node.dataset_set(
        :from_energy,
        Atlas::NodeAttributes::EnergyToMolecules.new(conversion_attributes)
      )
    end.future.graph
  end

  let(:molecule_graph) { graph.plugin(:molecules).molecule_graph }
  let(:energy_node) { graph.node(:foo) }
  let(:molecule_node) { molecule_graph.node(:m_left) }

  context 'when the molecule node uses demand without a conversion' do
    before do
      graph.calculate
    end

    it 'has a non-nil demand' do
      expect(molecule_node.demand).not_to be_nil
    end

    it 'sets demand of the molecule node' do
      expect(molecule_node.demand).to eq(energy_node.demand)
    end
  end

  context 'when the molecule node uses demand with a conversion' do
    let(:conversion_attributes) { super().merge(conversion: 0.5) }

    before do
      graph.calculate
    end

    it 'has a non-nil demand' do
      expect(molecule_node.demand).not_to be_nil
    end

    it 'sets demand of the molecule node' do
      expect(molecule_node.demand).to eq(energy_node.demand * 0.5)
    end
  end

  context 'when the molecule node uses input with a conversion' do
    let(:conversion_attributes) do
      super().merge(direction: :input, conversion: { electricity: 0.5, gas: 1.0 })
    end

    before do
      allow(energy_node.query).to receive(:input_of).with(:electricity).and_return(100)
      allow(energy_node.query).to receive(:input_of).with(:gas).and_return(10)

      graph.calculate
    end

    it 'has a non-nil demand' do
      expect(molecule_node.demand).not_to be_nil
    end

    it 'sets demand of the molecule node' do
      expect(molecule_node.demand).to eq(60) # 50% of elec. 100% of gas.
    end
  end

  context 'when the molecule node uses output with a conversion' do
    let(:conversion_attributes) do
      super().merge(direction: :output, conversion: { electricity: 0.25, gas: 1.0 })
    end

    before do
      allow(energy_node.query).to receive(:output_of).with(:electricity).and_return(100)
      allow(energy_node.query).to receive(:output_of).with(:gas).and_return(10)

      graph.calculate
    end

    it 'has a non-nil demand' do
      expect(molecule_node.demand).not_to be_nil
    end

    it 'sets demand of the molecule node' do
      expect(molecule_node.demand).to eq(35) # 25% of elec. 100% of gas.
    end
  end
end
