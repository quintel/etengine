require 'spec_helper'

describe Qernel::Plugins::Merit::Util do
  describe '.add_curves' do
    context 'with two curves of [1, 2, 1, 2]' do
      let(:result) do
        Qernel::Plugins::Merit::Util.add_curves([
          Merit::Curve.new([1.0, 2.0] * 2),
          Merit::Curve.new([1.0, 2.0] * 2),
        ])
      end

      it 'returns a Merit::Curve' do
        expect(result).to be_a(Merit::Curve)
      end

      it 'returns a curve with four elements' do
        expect(result.length).to eq(4)
      end

      it 'returns a curve of [2, 4, 2, 4]' do
        expect(result.take(4)).to eq([2, 4, 2, 4])
      end
    end # with two curves of [1, 2, 1, 2]

    context 'with 26 curves alternating [1, 2, 1, 2] and [1, 2, 3, 4]' do
      let(:result) do
        c1 = Merit::Curve.new([1.0, 2.0, 1.0, 2.0])
        c2 = Merit::Curve.new([1.0, 2.0, 3.0, 4.0])

        Qernel::Plugins::Merit::Util.add_curves([c1, c2] * 13)
      end

      it 'returns a Merit::Curve' do
        expect(result).to be_a(Merit::Curve)
      end

      it 'returns a curve with four elements' do
        expect(result.length).to eq(4)
      end

      it 'returns a curve of [26, 52, 52, 78]' do
        expect(result.take(4)).to eq([26, 52, 52, 78])
      end
    end # with 26 curves alternating [1, 2, 1, 2] and [1, 2, 3, 4]
  end
end
