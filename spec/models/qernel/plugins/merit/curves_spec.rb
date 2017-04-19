require 'spec_helper'

describe 'Qernel::Plugins::Merit::Curves' do
  let(:ev_demand) { 1.0 }
  let(:ev_mix)    { [0.75, 0.25, 0] }
  let(:curves)    { Qernel::Plugins::Merit::Curves.new(graph) }
  let(:region)    { 'nl' }

  let(:graph) do
    graph     = double('Qernel::Graph')
    graph_api = double('Qernel::GraphApi')
    area      = double('Qernel::Area')

    allow(area).to receive(:area_code).and_return(region)
    allow(area).to receive(:electric_vehicle_profile_1).and_return(ev_mix[0])
    allow(area).to receive(:electric_vehicle_profile_2).and_return(ev_mix[1])
    allow(area).to receive(:electric_vehicle_profile_3).and_return(ev_mix[2])

    allow(graph_api)
      .to receive(:group_demand_for_electricity)
      .with(:ev_demand).and_return(ev_demand)

    allow(graph).to receive(:area).and_return(area)
    allow(graph).to receive(:query).and_return(graph_api)

    graph
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
end
