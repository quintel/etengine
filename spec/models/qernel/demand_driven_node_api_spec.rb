require 'spec_helper'

module Qernel
  describe DemandDrivenNodeApi do
    let(:graph) do
      layout = <<-LAYOUT.strip_heredoc
        useable_heat: network(100) == s(0.25) ==> supply_one
        useable_heat: network      == s(0.75) ==> supply_two
      LAYOUT

      GraphParser.new(layout).build
    end # graph

    let(:network)    { graph.nodes.detect { |c| c.key == :network    } }
    let(:supply_one) { graph.nodes.detect { |c| c.key == :supply_one } }
    let(:supply_two) { graph.nodes.detect { |c| c.key == :supply_two } }

    before do
      allow(graph.area).to receive(:number_of_residences).and_return(200)

      supply_one.node_api = DemandDrivenNodeApi.new(supply_one)
      supply_two.node_api = DemandDrivenNodeApi.new(supply_two)

      [ supply_one, supply_two ].each do |node|
        node.graph = graph

        api = node.node_api
        allow(api).to receive(:nominal_capacity_heat_output_per_unit).and_return(20)
        allow(api).to receive(:demand_of_hot_water).and_return(0)
        allow(api).to receive(:demand_of_steam_hot_water).and_return(0)
        allow(api).to receive(:demand_of_useable_heat).and_return(0)
      end
    end

    # ------------------------------------------------------------------------

    describe '#number_of_units' do
      describe 'when households_supplied_per_unit is 1' do
        it 'should be 50.0 when the node has a 25% share' do
          expect(supply_one.node_api.number_of_units).to eql(50.0)
        end

        it 'should be 150.0 when the node has a 75% share' do
          expect(supply_two.node_api.number_of_units).to eql(150.0)
        end
      end

      describe 'when households_supplied_per_unit is 25' do
        before do
          [ supply_one, supply_two ].each do |node|
            node.dataset_set(:households_supplied_per_unit, 25)
          end
        end

        it 'should be 2.0 when the node has a 25% share' do
          expect(supply_one.node_api.number_of_units).to eql(2.0)
        end

        it 'should be 6.0 when the node has a 75% share' do
          expect(supply_two.node_api.number_of_units).to eql(6.0)
        end
      end

      describe 'when source data has a `nil` value' do
        before {  supply_one.node_api.dataset_set(:number_of_units, nil) }

        it 'should ignore the nil and compute the value' do
          expect(supply_one.node_api.number_of_units).not_to be_nil
        end
      end
    end # number_of_units

    # ------------------------------------------------------------------------

    describe '#full_load_seconds' do
      let(:api) { supply_one.node_api }

      context 'when households_supplied_per_unit is 1' do
        it 'should calculate' do
          allow(api).to receive(:demand_of_useable_heat).and_return(50)
          expect(api.full_load_seconds).to eql(0.05)
        end

        it 'should scale with demand' do
          allow(api).to receive(:demand_of_useable_heat).and_return(500)
          expect(api.full_load_seconds).to eql(0.5)
        end
      end

      context 'when households_supplied_per_unit is 25' do
        before { supply_one.dataset_set(:households_supplied_per_unit, 25) }

        it 'should calculate' do
          allow(api).to receive(:demand_of_useable_heat).and_return(50)
          expect(api.full_load_seconds).to eql(1.25)
        end

        it 'should scale with demand' do
          allow(api).to receive(:demand_of_useable_heat).and_return(500)
          expect(api.full_load_seconds).to eql(12.5)
        end
      end
    end # full_load_seconds

    # ------------------------------------------------------------------------

    describe '#full_load_hours' do
      let(:api) { supply_one.node_api }

      it 'should be based on full_load_seconds' do
        allow(api).to receive(:demand_of_useable_heat).and_return(50)
        seconds = api.full_load_seconds

        expect(api.full_load_hours).to eql(seconds / 3600)
      end

      it 'should scale with demand' do
        allow(api).to receive(:demand_of_useable_heat).and_return(500)
        seconds = api.full_load_seconds

        expect(api.full_load_hours).to eql(seconds / 3600)
      end
    end # full_load_hours

  end # DemandDrivenNodeApi
end # Qernel
