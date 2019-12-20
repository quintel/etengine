require 'spec_helper'

describe Qernel::Causality::Util do
  describe '.amplify_curve' do
    describe 'with a curve of [0.25, 0.25, 0.5, 1.0] (2flh)' do
      let(:curve) { [0.25, 0.5, 0.75, 1.0].map { |v| v / 3600.0 / 2 } }

      context 'amplifying to 3flh' do
        let(:result) do
          described_class.amplify_curve(curve, 3.0)
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
          described_class.amplify_curve(curve, 20.0)
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
          described_class.amplify_curve(curve, 1.0)
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
