require 'spec_helper'

RSpec.describe Qernel::Plugins::Merit::SimpleHouseholdHeat, :household_curves do
  let(:household_heat) do
    Qernel::Plugins::Merit::SimpleHouseholdHeat.new(graph, create_curve_set)
  end

  describe 'space_heating_demand' do
    let(:graph) { stub_space_heating(create_graph, demand: demand) }

    context 'when demand is zero' do
      let(:demand) { 0.0 }

      it 'returns a Merit::Curve' do
        expect(household_heat.space_heating_demand).to be_a(Merit::Curve)
      end

      it 'has a sum of 0' do
        expect(household_heat.space_heating_demand.to_a.sum).to eq(0)
      end

      it 'requests the demand from the Graph' do
        household_heat.space_heating_demand

        expect(graph.query)
          .to have_received(:group_demand_for_electricity)
          .with(:merit_household_space_heating_producers)
      end
    end

    context 'when demand is 1000' do
      let(:demand) { 1000.0 }

      it 'returns a Merit::Curve' do
        expect(household_heat.space_heating_demand).to be_a(Merit::Curve)
      end

      it 'has a sum of 1000' do
        expect(household_heat.space_heating_demand.to_a.sum)
          .to be_within(1e-9).of(1000)
      end

      it 'requests the demand from the Graph' do
        household_heat.space_heating_demand

        expect(graph.query)
          .to have_received(:group_demand_for_electricity)
          .with(:merit_household_space_heating_producers)
      end
    end
  end # space heating demand

  describe 'hot_water_demand' do
    let(:graph) { stub_hot_water(create_graph, demand: demand) }

    context 'when demand is 10' do
      let(:demand) { 10.0 }

      it 'returns a Merit::Curve' do
        expect(household_heat.hot_water_demand).to be_a(Merit::Curve)
      end

      it 'has a sum of 10' do
        expect(household_heat.hot_water_demand.to_a.sum)
          .to be_within(1e-9).of(10)
      end
    end
  end # hot water demand
end
