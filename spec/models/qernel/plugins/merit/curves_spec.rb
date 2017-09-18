require 'spec_helper'

describe Qernel::Plugins::Merit::Curves, :household_curves do
  let(:graph)  { create_graph(area_code: region) }
  let(:region) { :nl }

  let(:curves) do
    Qernel::Plugins::Merit::Curves.new(
      graph,
      Qernel::Plugins::Merit::SimpleHouseholdHeat.new(graph, create_curve_set)
    )
  end

  describe 'electric car curves' do
    let(:ev_demand) { 8760.0 }
    let(:ev_mix)    { [0.75, 0.25, 0] }

    before do
      allow(graph.area)
        .to receive(:electric_vehicle_profile_1_share)
        .and_return(ev_mix[0])

      allow(graph.area)
        .to receive(:electric_vehicle_profile_2_share)
        .and_return(ev_mix[1])

      allow(graph.area)
        .to receive(:electric_vehicle_profile_3_share)
        .and_return(ev_mix[2])

      allow(graph.query)
        .to receive(:group_demand_for_electricity)
        .with(:merit_ev_demand).and_return(ev_demand)
    end

    describe 'with a 50/50 mix' do
      let(:ev_mix) { [0.5, 0.5, 0.0] }

      it 'creates a combined profile' do
        # ev1 = [1.0, 0.0, 1.0, 0.0, ...]
        # ev2 = [0.0, 1.0, 0.0, 1.0, ...]
        expect(curves.ev_demand.take(4)).to eq([1.0, 1.0, 1.0, 1.0])
      end

      it 'has an area equal to demand' do
        expect(curves.ev_demand.sum).to eq(ev_demand)
      end
    end

    describe 'with a 75/25 mix' do
      let(:ev_mix) { [0.75, 0.25, 0.0] }

      it 'creates a combined profile' do
        expect(curves.ev_demand.take(4)).to eq([1.5, 0.5, 1.5, 0.5])
      end

      it 'has an area equal to demand' do
        expect(curves.ev_demand.sum).to eq(ev_demand)
      end
    end

    describe 'with a 30/30/40 mix' do
      let(:ev_mix) { [0.3, 0.3, 0.4] }

      it 'creates a combined profile' do
        # 8760 * 0.4 * 1.0 +             # 3504.0
        #   8760 * 0.3 * (2.0 / 8760) +  #    0.3
        #   8760 * 0.3 * (0.0 / 8760)    #    0.0
        expect(curves.ev_demand.take(4)).to eq([3504.6, 0.6, 0.6, 0.6])
      end

      it 'has an area equal to demand' do
        expect(curves.ev_demand.sum).to be_within(1e-5).of(ev_demand)
      end
    end

    describe 'when the dataset has no profiles' do
      let(:region) { :eu }

      it 'creates a zeroed profile' do
        expect(curves.ev_demand.take(4)).to eq([0.0, 0.0, 0.0, 0.0])
      end

      it 'has a sum of 0.0' do
        expect(curves.ev_demand.sum).to be_zero
      end
    end
  end # electric vehicle profiles

  describe 'household hot water demand' do
    before do
      stub_hot_water(graph, demand: hot_water_demand)
    end

    let(:curve) { curves.household_hot_water_demand }

    context 'with hot water demand of 8760' do
      let(:hot_water_demand) { 8760.0 }

      it 'creates a profile with one entry per-hour' do
        expect(curve.length).to eq(8760)
      end

      it 'scaled the profile by demand' do
        expect(curve.take(4)).to eq([2.0, 0.0, 2.0, 0.0])
      end

      it 'has an area equal to demand' do
        expect(curve.sum).to eq(8760)
      end
    end

    context 'with no hot water demand' do
      let(:hot_water_demand) { 0.0 }

      it 'creates a profile with one entry per-hour' do
        expect(curve.length).to eq(8760)
      end

      it 'scaled the profile by demand' do
        expect(curve.take(4)).to eq([0.0, 0.0, 0.0, 0.0])
      end

      it 'has an area of zero' do
        expect(curve.sum).to eq(0)
      end
    end
  end # household hot water demand
end
