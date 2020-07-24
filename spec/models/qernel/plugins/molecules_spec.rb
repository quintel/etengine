# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::Plugins::Molecules do
  let(:conversion_attributes) { { source: :molecule_source } }

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
  let(:energy_node) { graph.node(:molecule_source) }
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
      super().merge(direction: :input, conversion: { electricity: 0.5, natural_gas: 1.0 })
    end

    before do
      allow(energy_node.input(:electricity)).to receive(:external_value).and_return(100)
      allow(energy_node.input(:natural_gas)).to receive(:external_value).and_return(10)

      graph.calculate
    end

    it 'has a non-nil demand' do
      expect(molecule_node.demand).not_to be_nil
    end

    it 'sets demand of the molecule node' do
      expect(molecule_node.demand).to eq(60) # 50% of elec. 100% of natural gas.
    end
  end

  context 'when the molecule node uses input with a carrier attribute' do
    let(:conversion_attributes) do
      super().merge(direction: :input, conversion: {
        electricity: 'carrier: co2_conversion_per_mj',
        natural_gas: 1.0
      })
    end

    before do
      allow(energy_node.input(:electricity).carrier)
        .to receive(:co2_conversion_per_mj).and_return(0.3)

      allow(energy_node.input(:electricity)).to receive(:external_value).and_return(100)
      allow(energy_node.input(:natural_gas)).to receive(:external_value).and_return(10)

      graph.calculate
    end

    it 'has a non-nil demand' do
      expect(molecule_node.demand).not_to be_nil
    end

    it 'sets demand of the molecule node' do
      expect(molecule_node.demand).to eq(40) # 30% of elec. 100% of natural gas.
    end
  end

  context "when the molecule node uses input with a carrier attribute which doesn't exist" do
    let(:conversion_attributes) do
      super().merge(direction: :input, conversion: {
        electricity: 'carrier: not_a_real_attribute'
      })
    end

    it 'raises an error' do
      expect { graph.calculate }.to raise_error(
        'Invalid attribute for electricity carrier in `from_energy` on molecule_source node'
      )
    end
  end

  context 'when the molecule node uses output with a conversion' do
    let(:conversion_attributes) do
      super().merge(direction: :output, conversion: { electricity: 0.25, natural_gas: 1.0 })
    end

    before do
      allow(energy_node.output(:electricity)).to receive(:external_value).and_return(100)
      allow(energy_node.output(:natural_gas)).to receive(:external_value).and_return(10)

      graph.calculate
    end

    it 'has a non-nil demand' do
      expect(molecule_node.demand).not_to be_nil
    end

    it 'sets demand of the molecule node' do
      expect(molecule_node.demand).to eq(35) # 25% of elec. 100% of natural gas.
    end
  end
end
