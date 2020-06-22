require 'spec_helper'

describe Qernel::FeverFacade::Curves, :household_curves do
  let(:graph) do
    create_graph(area_code: region, weather_curve_set: curve_set)
  end

  let(:region)    { :nl }
  let(:curve_set) { 0.0 }

  let(:curves) do
    Qernel::FeverFacade::Curves.new(graph)
  end

  let(:node) { instance_double('Qernel::Node', demand: 8760) }
  let(:curve) { curves.curve(curve_name, node) }

  # The curve is converted so as to sum to 1.0; this converts it to something
  # mething more readable.
  let(:normalized_curve) { curve * 8760 }

  describe 'load profiles' do
    context 'when the file exists' do
      let(:curve_name) { 'dhw_normalized' }

      it 'returns the curve' do
        expect(curve).to be_a(Merit::Curve)
      end
    end

    context 'when the file does not exist' do
      let(:curve_name) { 'does_not_exist' }

      it 'raises an error' do
        expect { curve }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe 'weather set curves' do
    context 'when the file exists' do
      let(:curve_name) { 'weather/insulation_detached_houses_low' }

      it 'returns the curve' do
        expect(curve).to be_a(Merit::Curve)
      end
    end

    context 'when the file does not exist' do
      let(:curve_name) { 'weather/insulation_detached_houses_nope' }

      it 'raises an error' do
        expect { curve }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when the curve set does not exist' do
      let(:curve_name) { 'nope/insulation_detached_houses_low' }

      it 'raises an error' do
        expect { curve }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe 'dynamic curves' do
    let(:curve_mix) { [0.75, 0.25, 0] }
    let(:curve_name) { 'dynamic: detached_houses_heat' }

    before do
      allow(graph.area)
        .to receive(:insulation_detached_houses_low_share)
        .and_return(curve_mix[0])

      allow(graph.area)
        .to receive(:insulation_detached_houses_medium_share)
        .and_return(curve_mix[1])

      allow(graph.area)
        .to receive(:insulation_detached_houses_high_share)
        .and_return(curve_mix[2])
    end

    describe 'with a 50/50/0 mix' do
      let(:curve_mix) { [0.5, 0.5, 0.0] }

      it 'creates a combined curve' do
        # ev1 = [1.0, 0.0, 1.0, 0.0, ...]
        # ev2 = [0.0, 1.0, 0.0, 1.0, ...]
        expect(normalized_curve.take(4)).to eq([1.0, 1.0, 1.0, 1.0])
      end

      it 'has an area of 1' do
        expect(curve.sum).to be_within(1e-8).of(1)
      end
    end

    describe 'with a 75/25/0 mix' do
      let(:curve_mix) { [0.75, 0.25, 0.0] }

      it 'creates a combined curve' do
        expect(normalized_curve.take(4)).to eq([1.5, 0.5, 1.5, 0.5])
      end

      it 'has an area of 1' do
        expect(curve.sum).to be_within(1e-8).of(1)
      end
    end

    describe 'with a 30/30/40 mix' do
      let(:curve_mix) { [0.3, 0.3, 0.4] }

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
