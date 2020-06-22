require 'spec_helper'

describe Qernel::MeritFacade::Curves, :household_curves do
  let(:graph)  { create_graph(area_code: region) }
  let(:region) { :nl }

  let(:curves) do
    described_class.new(
      graph,
      Qernel::MeritFacade::Context.new(nil, nil, :carrier, :attribute, nil),
      Qernel::MeritFacade::SimpleHouseholdHeat.new(graph, create_curve_set)
    )
  end

  describe 'amplified dynamic curves with a source curve of 1920 FLH' do
    let(:node) do
      instance_double(
        'Qernel::NodeApi',
        demand: 8760,
        full_load_hours: full_load_hours
      )
    end

    let(:curve) { curves.curve('dynamic: wind_inland', node) }

    context 'with a node FLH of 1000' do
      let(:full_load_hours) { 1000 }

      it 'creates a curve with 1920 full load hours' do
        max = curve.max
        expect(curve.sum { |val| val / max }.to_i).to eq(1920)
      end
    end

    context 'with a node FLH of 1920' do
      let(:full_load_hours) { 1920 }

      it 'creates a curve with 1920 full load hours' do
        max = curve.max
        expect(curve.sum { |val| val / max }.to_i).to eq(1920)
      end
    end

    context 'with a node FLH of 2200' do
      let(:full_load_hours) { 2200 }

      it 'creates a curve with 2200 full load hours' do
        max = curve.max
        expect(curve.sum { |val| val / max }.to_i).to eq(2200)
      end
    end
  end

  describe 'interpolated dynamic curves' do
    let(:node) { instance_double('Qernel::NodeApi', demand: 8760) }
    let(:ev_mix) { [0.75, 0.25, 0] }
    let(:curve) { curves.curve('dynamic: ev_demand', node) }

    # The curve is converted so as to sum to 1.0; this converts it to something
    # more readable.
    let(:normalized_curve) { curve * 8760 }

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

      it 'creates a combined curve' do
        # ev1 = [1.0, 0.0, 1.0, 0.0, ...]
        # ev2 = [0.0, 1.0, 0.0, 1.0, ...]
        expect(normalized_curve.take(4)).to eq([1.0, 1.0, 1.0, 1.0])
      end

      it 'has an area of 1' do
        expect(curve.sum).to be_within(1e-8).of(1)
      end
    end

    describe 'with a 75/25 mix' do
      let(:ev_mix) { [0.75, 0.25, 0.0] }

      it 'creates a combined curve' do
        expect(normalized_curve.take(4)).to eq([1.5, 0.5, 1.5, 0.5])
      end

      it 'has an area of 1' do
        expect(curve.sum).to be_within(1e-8).of(1)
      end
    end

    describe 'with a 30/30/40 mix' do
      let(:ev_mix) { [0.3, 0.3, 0.4] }

      it 'creates a combined curve' do
        # 8760 * 0.4 * 1.0 +             # 3504.0
        #   8760 * 0.3 * (2.0 / 8760) +  #    0.3
        #   8760 * 0.3 * (0.0 / 8760)    #    0.0
        expect(normalized_curve.take(4)).to eq([3504.6, 0.6, 0.6, 0.6])
      end

      it 'has an area of 1' do
        expect(curve.sum).to be_within(1e-8).of(1)
      end
    end

    describe 'when the dataset has no curves' do
      let(:region) { :eu }

      it 'raises an error' do
        expect { normalized_curve }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
