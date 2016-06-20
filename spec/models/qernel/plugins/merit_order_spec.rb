require 'spec_helper'

module Qernel::Plugins
  describe MeritOrder do
    before(:each) do
      converters = gql.present.graph.converters + gql.future.graph.converters
      attrs      = [ :electricity_output_conversion, :input_capacity,
                     :mwh_electricity, :fixed_costs, :marginal_costs,
                     :fixed_operation_and_maintenance_costs_per_year,
                     :number_of_units, :full_load_hours, :availability ]

      converters.product(attrs).each do |converter, attribute|
        converter.query.stub(attribute).and_return(1.0)
      end

      gql.future.graph.query.
        stub(:total_demand_for_electricity).and_return(100.0)
    end

    describe 'when the scenario has the MeritOrder disabled' do
      let(:gql) do
        Scenario.default(
          user_values: { settings_enable_merit_order: 0 }
        ).gql(prepare: false)
      end

      it 'uses the SimpleMeritOrder plugin on the present graph' do
        gql.prepare

        graph = gql.present.graph
        graph.calculate

        expect(graph.lifecycle.plugins[:merit]).to be_a(SimpleMeritOrder)
        expect(graph.lifecycle.plugins[:merit]).to_not be_a(MeritOrder)
      end

      it 'uses the SimpleMeritOrder plugin on the future graph' do
        gql.prepare

        graph = gql.future.graph
        graph.calculate

        expect(graph.lifecycle.plugins[:merit]).to be_a(SimpleMeritOrder)
        expect(graph.lifecycle.plugins[:merit]).to_not be_a(MeritOrder)
      end
    end # when the scenario has the MeritOrder disabled

    describe 'when the scenario has the MeritOrder enabled' do
      let(:gql) do
        Scenario.default(
          user_values: { settings_enable_merit_order: 1 }
        ).gql(prepare: false)
      end

      it 'uses the SimpleMeritOrder plugin on the present graph' do
        gql.prepare

        graph = gql.present.graph

        expect(graph.lifecycle.plugins[:merit]).to be_a(SimpleMeritOrder)
        expect(graph.lifecycle.plugins[:merit]).to_not be_a(MeritOrder)
      end

      it 'uses the MeritOrder plugin on the future graph' do
        gql.prepare

        graph = gql.future.graph

        expect(graph.lifecycle.plugins[:merit]).to be_a(MeritOrder)
      end

      it 'calculates the future graph twice' do
        gql.init_datasets
        gql.update_graphs

        expect(gql.future.graph.lifecycle).to receive(:do_calculation)
          .exactly(2).times.and_call_original

        gql.calculate_graphs
      end
    end # when the scenario has the MeritOrder enabled
  end # MeritOrder
end # Qernel::Plugins
