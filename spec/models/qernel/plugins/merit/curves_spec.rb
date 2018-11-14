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

  describe 'dynamic curves' do
    let(:converter) { instance_double('Qernel::Converter', demand: 8760) }
    let(:ev_mix)  { [0.75, 0.25, 0] }
    let(:profile) { curves.profile('dynamic: ev_demand', converter) }

    # The profile is converted so as to sum to 1.0; this converts it to
    # something more readable.
    let(:normalized_profile) { profile * 8760 }

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
    end

    describe 'with a 50/50 mix' do
      let(:ev_mix) { [0.5, 0.5, 0.0] }

      it 'creates a combined profile' do
        # ev1 = [1.0, 0.0, 1.0, 0.0, ...]
        # ev2 = [0.0, 1.0, 0.0, 1.0, ...]
        expect(normalized_profile.take(4)).to eq([1.0, 1.0, 1.0, 1.0])
      end

      it 'has an area of 1' do
        expect(profile.sum).to be_within(1e-8).of(1)
      end
    end

    describe 'with a 75/25 mix' do
      let(:ev_mix) { [0.75, 0.25, 0.0] }

      it 'creates a combined profile' do
        expect(normalized_profile.take(4)).to eq([1.5, 0.5, 1.5, 0.5])
      end

      it 'has an area of 1' do
        expect(profile.sum).to be_within(1e-8).of(1)
      end
    end

    describe 'with a 30/30/40 mix' do
      let(:ev_mix) { [0.3, 0.3, 0.4] }

      it 'creates a combined profile' do
        # 8760 * 0.4 * 1.0 +             # 3504.0
        #   8760 * 0.3 * (2.0 / 8760) +  #    0.3
        #   8760 * 0.3 * (0.0 / 8760)    #    0.0
        expect(normalized_profile.take(4)).to eq([3504.6, 0.6, 0.6, 0.6])
      end

      it 'has an area of 1' do
        expect(profile.sum).to be_within(1e-8).of(1)
      end
    end

    describe 'when the dataset has no profiles' do
      let(:region) { :eu }

      it 'raises an error' do
        expect { normalized_profile }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
