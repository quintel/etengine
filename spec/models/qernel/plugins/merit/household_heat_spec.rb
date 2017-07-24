require 'spec_helper'

describe Qernel::Plugins::Merit::HouseholdHeat do
  let(:helper) do
    helper = described_class.new(graph)
    allow(helper).to receive(:demand_for_heat).and_return(heat_demand)
    helper
  end

  let(:old_household_demand) { 0.0 }
  let(:new_household_demand) { 0.0 }
  let(:heat_demand)   { 0.0 }

  let(:graph) do
    api   = double('Qernel::GraphApi')
    graph = double('Qernel::Graph', query: api)

    old_house = double('Old household', demand: old_household_demand)
    new_house = double('New household', demand: new_household_demand)

    allow(graph).to receive(:group_converters)
      .with(:merit_old_household_heat)
      .and_return([old_house])

    allow(graph).to receive(:group_converters)
      .with(:merit_new_household_heat)
      .and_return([new_house])

    graph
  end

  context 'with electricity demand of 1000' do
    let(:heat_demand) { 1000.0 }

    context 'with 100% new houses' do
      let(:new_household_demand) { 100.0 }
      let(:old_household_demand) { 0.0 }

      it 'has total electricity demand of 1000' do
        expect(helper.demand_for_heat).to eq(1000)
      end

      it 'has 0% share of old households' do
        expect(helper.share_of(:old)).to eq(0)
      end

      it 'has no electricity demand in old households' do
        expect(helper.demand_of(:old)).to eq(0)
      end

      it 'has 100% share of new households' do
        expect(helper.share_of(:new)).to eq(1.0)
      end

      it 'has 1000 electricity demand in new households' do
        expect(helper.demand_of(:new)).to eq(1000)
      end
    end # with 100% new houses

    context 'with 100% old houses' do
      let(:new_household_demand) { 0.0 }
      let(:old_household_demand) { 100.0 }

      it 'has total electricity demand of 1000' do
        expect(helper.demand_for_heat).to eq(1000)
      end

      it 'has 100% share of old households' do
        expect(helper.share_of(:old)).to eq(1.0)
      end

      it 'has 1000 electricity demand in old households' do
        expect(helper.demand_of(:old)).to eq(1000)
      end

      it 'has 0% share of new households' do
        expect(helper.share_of(:new)).to eq(0)
      end

      it 'has no electricity demand in new households' do
        expect(helper.demand_of(:new)).to eq(0)
      end
    end # with 100% old houses

    context 'with 40% old houses, 60% new houses' do
      let(:new_household_demand) { 60.0 }
      let(:old_household_demand) { 40.0 }

      it 'has total electricity demand of 1000' do
        expect(helper.demand_for_heat).to eq(1000)
      end

      it 'has 40% share of old households' do
        expect(helper.share_of(:old)).to eq(0.4)
      end

      it 'has 400 electricity demand in old households' do
        expect(helper.demand_of(:old)).to eq(400)
      end

      it 'has 60% share of new households' do
        expect(helper.share_of(:new)).to eq(0.6)
      end

      it 'has 600 electricity demand in new households' do
        expect(helper.demand_of(:new)).to eq(600)
      end
    end # with 40% old houses, 60% new houses

    context 'with no heat demand' do
      let(:new_household_demand) { 0.0 }
      let(:old_household_demand) { 0.0 }

      it 'has total electricity demand of 1000' do
        expect(helper.demand_for_heat).to eq(1000)
      end

      it 'has 0% share of old households' do
        expect(helper.share_of(:old)).to eq(0)
      end

      it 'has no electricity demand in old households' do
        expect(helper.demand_of(:old)).to eq(0)
      end

      it 'has 0% share of new households' do
        expect(helper.share_of(:new)).to eq(0)
      end

      it 'has no electricity demand in new households' do
        expect(helper.demand_of(:new)).to eq(0)
      end
    end # with no heat demand
  end # with electricity demand of 1000

  context 'with no electricity demand' do
    let(:heat_demand) { 0.0 }

    context 'with 40% old houses, 60% new houses' do
      let(:new_household_demand) { 60.0 }
      let(:old_household_demand) { 40.0 }

      it 'has total electricity demand of zero' do
        expect(helper.demand_for_heat).to eq(0)
      end

      it 'has 40% share of old households' do
        expect(helper.share_of(:old)).to eq(0.4)
      end

      it 'has no electricity demand in old households' do
        expect(helper.demand_of(:old)).to eq(0)
      end

      it 'has 60% share of new households' do
        expect(helper.share_of(:new)).to eq(0.6)
      end

      it 'has no electricity demand in new households' do
        expect(helper.demand_of(:new)).to eq(0)
      end
    end # with 40% old houses, 60% new houses
  end
end
