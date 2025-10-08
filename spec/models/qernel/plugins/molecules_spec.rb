# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples_for 'running the molecule graph plugin' do
  let(:conversion_attributes) { { source: :molecule_source } }

  let(:graph) do
    gql = Scenario.default.gql
    graph = gql.future_graph
    node = graph.plugin(:molecules).molecule_graph.node(:m_left)

    node.dataset_set(
      :from_energy,
      Atlas::NodeAttributes::EnergyToMolecules.new(conversion_attributes)
    )

    allow(graph.area).to receive(:use_merit_order_demands).and_return(causality_enabled)
    graph
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
      allow(energy_node.input(:electricity)).to receive(:conversion).and_return(1.0)
      allow(energy_node.input(:natural_gas)).to receive(:conversion).and_return(0.1)

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

      allow(energy_node.input(:electricity)).to receive(:conversion).and_return(1.0)
      allow(energy_node.input(:natural_gas)).to receive(:conversion).and_return(0.1)

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
        'Invalid molecule conversion attribute for electricity carrier on molecule_source node: ' \
        '"carrier: not_a_real_attribute"'
      )
    end
  end

  context 'when the molecule node uses output with a conversion' do
    let(:conversion_attributes) do
      super().merge(direction: :output, conversion: { electricity: 0.25, natural_gas: 1.0 })
    end

    before do
      allow(energy_node.output(:electricity)).to receive(:conversion).and_return(1.0)
      allow(energy_node.output(:natural_gas)).to receive(:conversion).and_return(0.1)

      graph.calculate
    end

    it 'has a non-nil demand' do
      expect(molecule_node.demand).not_to be_nil
    end

    it 'sets demand of the molecule node' do
      expect(molecule_node.demand).to eq(35) # 25% of elec. 100% of natural gas.
    end
  end

  context 'when the molecule node uses input with a carrier attribute and a multiplier' do
    let(:conversion_attributes) do
      super().merge(direction: :input, conversion: {
        electricity: 'carrier: co2_conversion_per_mj, factor: 0.5',
        natural_gas: 1.0
      })
    end

    before do
      allow(energy_node.input(:electricity).carrier)
        .to receive(:co2_conversion_per_mj).and_return(0.4)

      allow(energy_node.input(:electricity)).to receive(:conversion).and_return(1.0)
      allow(energy_node.input(:natural_gas)).to receive(:conversion).and_return(0.1)

      graph.calculate
    end

    # electricity: 0.4 * 0.5 = 0.2, natural_gas: 1.0
    # demand = (energy_node.demand * 0.2) + (energy_node.demand * 0.1)
    # But input(:natural_gas).conversion is 0.1, so:
    # demand = (100 * 1.0 * 0.2) + (100 * 0.1 * 1.0) = 20 + 10 = 30
    it 'applies the multiplier to the carrier attribute' do
      expect(molecule_node.demand).to eq(30)
    end
  end
end

RSpec.describe Qernel::Plugins::Molecules do
  context 'when Causality is disabled' do
    include_examples 'running the molecule graph plugin' do
      let(:causality_enabled) { false }

      context 'when an energy node receives a value from the molecule graph' do
        before { graph.calculate }

        let(:energy_target) { graph.node(:molecule_target) }

        it 'has no demand' do
          expect(energy_target.demand).to be_nil
        end
      end
    end
  end

  context 'when Causality is enabled' do
    include_examples 'running the molecule graph plugin' do
      let(:causality_enabled) { true }

      context 'when an energy node receives a value from the molecule graph' do
        before { graph.calculate }

        let(:energy_target) { graph.node(:molecule_target) }

        it 'has a demand' do
          # m_left demand * 0.75 share to m_right_one * 0.75 conversion
          expect(energy_target.demand).to eq(100 * 0.75 * 0.75)
        end
      end
    end
  end
end
