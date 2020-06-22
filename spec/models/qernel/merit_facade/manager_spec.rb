require 'spec_helper'

describe Qernel::MeritFacade::Manager do
  before(:each) do
    nodes = gql.present.graph.nodes + gql.future.graph.nodes
    attrs      = [ :electricity_output_conversion, :input_capacity,
                    :mwh_electricity, :fixed_costs, :marginal_costs,
                    :fixed_operation_and_maintenance_costs_per_year,
                    :number_of_units, :full_load_hours, :availability ]

    nodes.product(attrs).each do |node, attribute|
      allow(node.query).to receive(attribute).and_return(1.0)
    end

    allow(gql.future.graph.query)
      .to receive(:total_demand_for_electricity)
      .and_return(100.0)

    allow(gql.future.graph.query)
      .to receive(:group_demand_for_electricity)
      .with(:merit_ev_demand).and_return(0.0)

    allow(gql.future.graph.query)
      .to receive(:group_demand_for_electricity)
      .with(:merit_household_space_heating_producers)
      .and_return(0)

    allow(gql.future.graph.query)
      .to receive(:group_demand_for_electricity)
      .with(:merit_household_hot_water_producers)
      .and_return(0)
  end

  describe 'when the scenario has the merit order disabled' do
    let(:gql) do
      Scenario.default(
        user_values: { settings_enable_merit_order: 0 }
      ).gql(prepare: false)
    end

    it 'uses the SimpleMeritOrder plugin on the present graph' do
      gql.prepare

      graph = gql.present.graph
      graph.calculate

      expect(graph.plugin(:merit)).to be_a(Qernel::Plugins::SimpleMeritOrder)
      expect(graph.plugin(:merit)).to_not be_a(described_class)
    end

    it 'uses the SimpleMeritOrder plugin on the future graph' do
      gql.prepare

      graph = gql.future.graph
      graph.calculate

      expect(graph.plugin(:merit)).to be_a(Qernel::Plugins::SimpleMeritOrder)
      expect(graph.plugin(:merit)).to_not be_a(described_class)
    end
  end # when the scenario has the MeritOrder disabled

  describe 'when the scenario has the merit order enabled' do
    let(:gql) do
      Scenario.default(
        user_values: { settings_enable_merit_order: 1 }
      ).gql(prepare: false)
    end

    it 'uses the SimpleMeritOrder plugin on the present graph' do
      gql.prepare

      graph = gql.present.graph

      expect(graph.plugin(:merit)).to be_a(Qernel::Plugins::SimpleMeritOrder)
      expect(graph.plugin(:merit)).to_not be_a(described_class)
    end

    it 'uses the MeritOrder plugin on the future graph' do
      gql.prepare

      graph = gql.future.graph

      expect(graph.plugin(:merit)).to be_a(described_class)
    end

    it 'calculates the future graph twice' do
      gql.init_datasets
      gql.update_graphs

      expect(gql.future.graph.lifecycle).to receive(:do_calculation)
        .exactly(2).times.and_call_original

      gql.calculate_graphs
    end
  end # when the scenario has the MeritOrder enabled
end # Manager
