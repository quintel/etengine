require 'spec_helper'

describe 'Qernel::Plugins::Merit::Curves' do
  let(:ev_demand) { 1.0 }
  let(:ev_mix)    { [0.75, 0.25, 0] }
  let(:curves)    { Qernel::Plugins::Merit::Curves.new(graph) }
  let(:region)    { 'nl' }

  # Stubs
  let(:area) { double('Qernel::Area') }
  let(:graph_api) { double('Qernel::GraphApi') }

  let(:graph) do
    graph = double('Qernel::Graph')

    allow(area).to receive(:area_code).and_return(region)

    allow(graph).to receive(:area).and_return(area)
    allow(graph).to receive(:query).and_return(graph_api)

    graph
  end

  describe 'electric car curves' do
    before do
      allow(area)
        .to receive(:electric_vehicle_profile_1)
        .and_return(ev_mix[0])

      allow(area)
        .to receive(:electric_vehicle_profile_2)
        .and_return(ev_mix[1])

      allow(area)
        .to receive(:electric_vehicle_profile_3)
        .and_return(ev_mix[2])

      allow(graph_api)
        .to receive(:group_demand_for_electricity)
        .with(:ev_demand).and_return(ev_demand)
    end

    describe 'with a 50/50 mix' do
      let(:ev_mix) { [0.5, 0.5, 0.0] }

      it 'creates a combined profile' do
        # ev1 = [1.0, 0.0, 1.0, 0.0, ...]
        # ev2 = [0.0, 1.0, 0.0, 1.0, ...]
        profile = curves.ev_demand
        values  = profile.to_a.take(4)

        expect(values.map { |v| v * 8760 }).to eq([1.0, 1.0, 1.0, 1.0])
      end

      it 'has a sum of 1.0' do
        profile = curves.ev_demand
        expect(profile.to_a.sum).to be_within(1e-5).of(1.0)
      end
    end

    describe 'with a 75/25 mix' do
      let(:ev_mix) { [0.75, 0.25, 0.0] }

      it 'creates a combined profile' do
        profile = curves.ev_demand
        values  = profile.to_a.take(4)

        expect(values.map { |v| v * 8760 }).to eq([1.5, 0.5, 1.5, 0.5])
      end

      it 'has a sum of 1.0' do
        profile = curves.ev_demand
        expect(profile.to_a.sum).to be_within(1e-5).of(1.0)
      end
    end

    describe 'with a 30/30/40 mix' do
      let(:ev_mix) { [0.3, 0.3, 0.4] }

      it 'creates a combined profile' do
        profile = curves.ev_demand
        values  = profile.to_a.take(4)

        # 8760 * 0.4 * 1.0 +             # 3504.0
        #   8760 * 0.3 * (2.0 / 8760) +  #    0.3
        #   8760 * 0.3 * (0.0 / 8760)    #    0.0

        expect(values.map { |v| v * 8760 }).to eq([3504.6, 0.6, 0.6, 0.6])
      end

      it 'has a sum of 1.0' do
        profile = curves.ev_demand
        expect(profile.to_a.sum).to be_within(1e-5).of(1.0)
      end
    end

    describe 'when the dataset has no profiles' do
      let(:region) { 'eu' }

      it 'creates a zeroed profile' do
        profile = curves.ev_demand
        values  = profile.to_a.take(4)

        expect(values.map { |v| v * 8760 }).to eq([0.0, 0.0, 0.0, 0.0])
      end

      it 'has a sum of 0.0' do
        profile = curves.ev_demand
        expect(profile.to_a.sum).to be_zero
      end
    end
  end # electric vehicle profiles

  describe 'new household heat demand with 45% old houses' do
    before do
      old_houses = double('old households converter', demand: 4.5)
      new_houses = double('new households converter', demand: 5.5)

      allow(area)
        .to receive(:insulation_profile_fraction_old_houses)
        .and_return(0.25)

      allow(graph)
        .to receive(:group_converters)
        .with(:old_household_heat)
        .and_return([old_houses])

      allow(graph)
        .to receive(:group_converters)
        .with(:new_household_heat)
        .and_return([new_houses])

      allow(graph_api)
        .to receive(:group_demand_for_electricity)
        .with(:household_heat_producers).and_return(8760.0)
    end

    context 'with a "share" of 0.25 (25/75 profile mix)' do
      it 'creates a combined profile' do
        values = curves.old_household_heat_demand.to_a.take(4)

        # Old households alone would have a profile of [0.5, 1.5, ...], however
        # since new households account for only 45% of heat demand, the result
        # should be as above * 0.45.

        expect(values).to eq([0.225, 0.675, 0.225, 0.675])
      end

      it 'has an area equal to demand' do
        profile = curves.old_household_heat_demand

        # x1 * 0.4 = demand share
        expect(profile.sum).to be_within(1e05).of(8760.0 * 0.45)
      end
    end
  end # old household heat demand

  describe 'new household heat demand with 75% new houses' do
    before do
      old_houses = double('old households converter', demand: 1.0)
      new_houses = double('new households converter', demand: 3.0)

      allow(area)
        .to receive(:insulation_profile_fraction_new_houses)
        .and_return(0.75)

      allow(graph)
        .to receive(:group_converters)
        .with(:old_household_heat)
        .and_return([old_houses])

      allow(graph)
        .to receive(:group_converters)
        .with(:new_household_heat)
        .and_return([new_houses])

      allow(graph_api)
        .to receive(:group_demand_for_electricity)
        .with(:household_heat_producers).and_return(8760.0)
    end

    context 'with a "share" of 0.75 (25/75 profile mix)' do
      it 'creates a combined profile' do
        values = curves.new_household_heat_demand.to_a.take(4)

        # New households alone would have a profile of [1.5, 0.5, ...], however
        # since new households account for only 75% of heat demand, the result
        # should be as above * 0.75.

        expect(values).to eq([1.125, 0.375, 1.125, 0.375])
      end

      it 'has an area equal to demand' do
        profile = curves.new_household_heat_demand

        # x * 0.75 = demand share
        expect(profile.sum).to eql(8760.0 * 0.75)
      end
    end
  end # new household heat demand
end
