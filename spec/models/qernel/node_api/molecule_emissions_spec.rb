# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::MoleculeEmissions do
  describe 'emission reporting methods for molecule nodes' do
    let(:graph) { Turbine::Graph.new }
    let(:node) { Qernel::Node.new(key: :test_node, graph_name: :molecules, groups: node_groups).with(demand: node_demand) }

    let(:node_demand) { 1000.0 }
    let(:node_groups) { [:emissions] }

    before do
      graph.add(node)
    end

    describe '#direct_reporting_emissions_co2_production' do
      context 'with a CO2 molecule node (has co2 carrier)' do
        before do
          # Mock the node to have a co2 input slot
          allow(node).to receive(:input).with(:co2).and_return(double('slot'))
          allow(node).to receive(:output).with(:co2).and_return(nil)
        end

        it 'returns the node demand' do
          expect(node.query.direct_reporting_emissions_co2_production).to eq(1000.0)
        end
      end

      context 'with a molecule node without co2 carrier' do
        before do
          allow(node).to receive(:input).with(:co2).and_return(nil)
          allow(node).to receive(:output).with(:co2).and_return(nil)
        end

        it 'returns 0.0' do
          expect(node.query.direct_reporting_emissions_co2_production).to eq(0.0)
        end
      end

      context 'with zero demand but co2 carrier' do
        let(:node_demand) { 0.0 }

        before do
          allow(node).to receive(:input).with(:co2).and_return(double('slot'))
        end

        it 'returns 0.0' do
          expect(node.query.direct_reporting_emissions_co2_production).to eq(0.0)
        end
      end

      context 'node not in emissions group' do
        let(:node_groups) { [] }

        it 'returns nil' do
          expect(node.query.direct_reporting_emissions_co2_production).to be_nil
        end
      end

      context 'with a CCUS captured node (ccus_captured group)' do
        let(:node_groups) { [:emissions, :ccus_captured] }

        before do
          allow(node).to receive(:input).with(:co2).and_return(double('slot'))
        end

        it 'returns 0.0 (excludes CCUS captured from production)' do
          expect(node.query.direct_reporting_emissions_co2_production).to eq(0.0)
        end
      end
    end

    describe '#direct_reporting_emissions_co2_capture' do
      context 'node in emissions group (not LULUCF)' do
        it 'returns 0.0' do
          expect(node.query.direct_reporting_emissions_co2_capture).to eq(0.0)
        end
      end

      context 'node not in emissions group' do
        let(:node_groups) { [] }

        it 'returns nil' do
          expect(node.query.direct_reporting_emissions_co2_capture).to be_nil
        end
      end

      context 'with a CCUS captured node (ccus_captured group)' do
        let(:node_groups) { [:emissions, :ccus_captured] }
        let(:node_demand) { 750.0 }

        it 'returns the node demand (includes CCUS captured as capture)' do
          expect(node.query.direct_reporting_emissions_co2_capture).to eq(750.0)
        end
      end
    end

    describe '#direct_reporting_emissions_other_ghg_emissions' do
      context 'with a molecule node with other_ghg carrier' do
        let(:node_demand) { 250.0 }

        before do
          allow(node).to receive(:input).with(:other_ghg).and_return(double('slot'))
          allow(node).to receive(:output).with(:other_ghg).and_return(nil)
        end

        it 'returns the node demand' do
          expect(node.query.direct_reporting_emissions_other_ghg_emissions).to eq(250.0)
        end
      end

      context 'with a CO2 node (no other_ghg carrier)' do
        before do
          allow(node).to receive(:input).with(:other_ghg).and_return(nil)
          allow(node).to receive(:output).with(:other_ghg).and_return(nil)
        end

        it 'returns 0.0' do
          expect(node.query.direct_reporting_emissions_other_ghg_emissions).to eq(0.0)
        end
      end

      context 'node not in emissions group' do
        let(:node_groups) { [] }

        it 'returns nil' do
          expect(node.query.direct_reporting_emissions_other_ghg_emissions).to be_nil
        end
      end
    end

    describe '#direct_reporting_emissions_total_ghg_emissions' do
      context 'with CO2 node' do
        before do
          allow(node).to receive(:input).with(:co2).and_return(double('slot'))
          allow(node).to receive(:output).with(:co2).and_return(nil)
          allow(node).to receive(:input).with(:other_ghg).and_return(nil)
          allow(node).to receive(:output).with(:other_ghg).and_return(nil)
        end

        it 'calculates total as CO2 production - capture + other GHG' do
          # Total = 1000 - 0 + 0 = 1000
          expect(node.query.direct_reporting_emissions_total_ghg_emissions).to eq(1000.0)
        end
      end

      context 'with other_ghg node' do
        let(:node_demand) { 150.0 }

        before do
          allow(node).to receive(:input).with(:co2).and_return(nil)
          allow(node).to receive(:output).with(:co2).and_return(nil)
          allow(node).to receive(:input).with(:other_ghg).and_return(double('slot'))
          allow(node).to receive(:output).with(:other_ghg).and_return(nil)
        end

        it 'calculates total as CO2 production - capture + other GHG' do
          # Total = 0 - 0 + 150 = 150
          expect(node.query.direct_reporting_emissions_total_ghg_emissions).to eq(150.0)
        end
      end

      context 'node not in emissions group' do
        let(:node_groups) { [] }

        it 'returns nil' do
          expect(node.query.direct_reporting_emissions_total_ghg_emissions).to be_nil
        end
      end

      context 'with a CCUS captured node' do
        let(:node_groups) { [:emissions, :ccus_captured] }
        let(:node_demand) { 400.0 }

        before do
          allow(node).to receive(:input).with(:co2).and_return(double('slot'))
          allow(node).to receive(:output).with(:co2).and_return(nil)
          allow(node).to receive(:input).with(:other_ghg).and_return(nil)
          allow(node).to receive(:output).with(:other_ghg).and_return(nil)
        end

        it 'calculates total as 0 production - 400 capture + 0 other GHG = -400' do
          # CO2 production = 0 (excluded due to CCUS captured group)
          # CO2 capture = 400 (included due to CCUS captured group)
          # Other GHG = 0
          # Total = 0 - 400 + 0 = -400
          expect(node.query.direct_reporting_emissions_total_ghg_emissions).to eq(-400.0)
        end
      end
    end

    describe '#ghg_carrier' do
      context 'with a co2 input slot' do
        before do
          co2_carrier = double('carrier', key: :co2)
          allow(node).to receive(:inputs).and_return([double('slot', carrier: co2_carrier)])
        end

        it 'returns CO2' do
          expect(node.query.ghg_carrier).to eq('CO2')
        end
      end

      context 'with an other_ghg input slot' do
        before do
          ghg_carrier = double('carrier', key: :other_ghg)
          allow(node).to receive(:inputs).and_return([double('slot', carrier: ghg_carrier)])
        end

        it 'returns Other GHG' do
          expect(node.query.ghg_carrier).to eq('Other GHG')
        end
      end
    end

    describe 'guard behavior' do
      let(:node_groups) { [] }

      it 'returns nil for all emission methods when node lacks emissions group' do
        expect(node.query.direct_reporting_emissions_co2_production).to be_nil
        expect(node.query.direct_reporting_emissions_co2_capture).to be_nil
        expect(node.query.direct_reporting_emissions_other_ghg_emissions).to be_nil
        expect(node.query.direct_reporting_emissions_total_ghg_emissions).to be_nil
      end
    end
  end
end
