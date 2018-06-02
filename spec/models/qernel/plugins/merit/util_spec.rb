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

    context 'with two arrays of [1, 2, 1, 2]' do
      let(:result) do
        Qernel::Plugins::Merit::Util.add_curves([
          [1.0, 2.0] * 2,
          [1.0, 2.0] * 2
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
    end # with two arrays of [1, 2, 1, 2]

    context 'with an array and curve of [1, 2, 1, 2]' do
      let(:result) do
        Qernel::Plugins::Merit::Util.add_curves([
          [1.0, 2.0] * 2,
          Merit::Curve.new([1.0, 2.0] * 2)
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
    end # with two arrays of [1, 2, 1, 2]

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

  describe '.amplify_curve' do
    describe 'with a curve of [0.25, 0.25, 0.5, 1.0] (2flh)' do
      let(:curve) { [0.25, 0.5, 0.75, 1.0].map { |v| v / 3600.0 / 2 } }

      context 'amplifying to 3flh' do
        let(:result) do
          Qernel::Plugins::Merit::Util.amplify_curve(curve, 3.0)
        end

        it 'returns a Merit::Curve' do
          expect(result).to be_a(Merit::Curve)
        end

        it 'returns a curve with four elements' do
          expect(result.length).to eq(4)
        end

        it 'returns a curve with FLH of 3.0' do
          max = result.max
          flh = result.map { |val| val / max }.sum

          expect(flh).to eq(3)
        end
      end

      context 'amplifying to 20flh' do
        let(:result) do
          Qernel::Plugins::Merit::Util.amplify_curve(curve, 20.0)
        end

        it 'returns a Merit::Curve' do
          expect(result).to be_a(Merit::Curve)
        end

        it 'returns a curve with four elements' do
          expect(result.length).to eq(4)
        end

        it 'returns a curve with FLH of 4.0' do
          max = result.max
          flh = result.map { |val| val / max }.sum

          expect(flh).to eq(4)
        end

        it 'maximises the curve' do
          expect(result.all? { |val| val == result.max }).to be(true)
        end
      end

      context 'amplifying to 1flh' do
        let(:result) do
          Qernel::Plugins::Merit::Util.amplify_curve(curve, 1.0)
        end

        it 'does not amplify the curve' do
          max = result.max
          flh = result.map { |val| val / max }.sum

          expect(flh).to eq(2.5)
        end
      end
    end # with a curve of [0.25, 0.25, 0.5, 1.0] (2flh)
  end
end
