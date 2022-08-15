# frozen_string_literal: true

require 'spec_helper'

module Gql::Runtime::Functions
  describe Curves, :etsource_fixture do
    let(:gql) { Scenario.default.gql(prepare: true) }

    let(:result) do |example|
      gql.query_future(example.metadata[:example_group][:description])
    end

    # CUMULATIVE_CURVE
    # ----------------

    describe 'CUMULATIVE_CURVE([])' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'CUMULATIVE_CURVE([1, 2, 3])' do
      it('returns [1, 3, 6]') { expect(result).to eq([1, 3, 6]) }
    end

    describe 'CUMULATIVE_CURVE([1, 2, -3, 4, -5])' do
      it('returns [1, 3, 0, 4, -1]') { expect(result).to eq([1, 3, 0, 4, -1]) }
    end

    # INVERT_CURVE
    # ------------

    describe 'INVERT_CURVE([1, 2, 3, -4, -5, -6])' do
      it('returns [-1, -2, -3, 4, 5, 6]') { expect(result).to eq([-1, -2, -3, 4, 5, 6]) }
    end

    describe 'INVERT_CURVE(0.0)' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'INVERT_CURVE(nil)' do
      it('returns []') { expect(result).to eq([]) }
    end

    # SUM_CURVES
    # ----------

    describe 'SUM_CURVES(0.0)' do
      it('returns []') { expect(result).to eq([]) }
      it('returns an Array') { expect(result).to be_a(Array) }
    end

    describe 'SUM_CURVES([[1]])' do
      it('returns [1]') { expect(result).to eq([1]) }
      it('returns an Array') { expect(result).to be_a(Array) }
    end

    describe 'SUM_CURVES([Merit.const_get(:Curve).new([1])])' do
      it('returns [1]') { expect(result).to eq([1]) }
      it('returns an Array') { expect(result).to be_a(Array) }
    end

    describe 'SUM_CURVES([1, 2, 3])' do
      it('returns [1, 2, 3]') { expect(result).to eq([1, 2, 3]) }
    end

    describe 'SUM_CURVES([])' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'SUM_CURVES([nil])' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'SUM_CURVES(nil)' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'SUM_CURVES([nil, nil])' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'SUM_CURVES([[], []])' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'SUM_CURVES(nil, nil)' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'SUM_CURVES([[1, 2], [3, 4]])' do
      it('returns [4, 6]') { expect(result).to eq([4, 6]) }
    end

    describe 'SUM_CURVES([1, 2], [3, 4])' do
      it('returns [4, 6]') { expect(result).to eq([4, 6]) }
    end

    describe 'SUM_CURVES([[1, 2], nil])' do
      it('returns [1, 2]') { expect(result).to eq([1, 2]) }
    end

    describe 'SUM_CURVES([1, 2], nil)' do
      it('returns [1, 2]') { expect(result).to eq([1, 2]) }
    end

    describe 'SUM_CURVES([1, 2], [3, 4], [5, 6])' do
      it('returns [9, 12]') { expect(result).to eq([9, 12]) }
    end

    describe 'SUM_CURVES([ElectricityDemandCurve])' do
      let(:result) do
        callable = ->(frame) { frame.to_f }
        curve = Qernel::FeverFacade::ElectricityDemandCurve.new([callable])

        gql.query_future(-> { SUM_CURVES(curve) })
      end

      it('returns [0, 1, 2, 3, ...]') do
        expect(result.take(4)).to eq([0, 1, 2, 3])
      end

      it('returns an Array') { expect(result).to be_a(Array) }
    end

    # PRODUCT_CURVES
    # --------------

    describe 'PRODUCT_CURVES([1, 2], [3, 4])' do
      it('returns [4, 6]') { expect(result).to eq([3, 8]) }
    end

    describe 'PRODUCT_CURVES([1, 2], nil)' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'PRODUCT_CURVES(nil, [1, 2])' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'PRODUCT_CURVES([], [])' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'PRODUCT_CURVES(nil, nil)' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'PRODUCT_CURVES(Merit.const_get(:Curve).new([1]), [2])' do
      it('returns [2]') { expect(result).to eq([2]) }
      it('returns an Array') { expect(result).to be_a(Array) }
    end

    describe 'PRODUCT_CURVES([[1, 2]], [3, 4])' do
      it('raises an error') do
        expect { result }.to raise_error(/first parameter had 1 nested curves/)
      end
    end

    describe 'PRODUCT_CURVES([1, 2], [[3, 4], [5, 6]])' do
      it('raises an error') do
        expect { result }.to raise_error(/second parameter had 2 nested curves/)
      end
    end

    describe 'PRODUCT_CURVES([1, 2, 3], [4, 5])' do
      it('returns [4, 6]') do
        expect { result }
          .to raise_error('Mismatch in curve lengths given to PRODUCT_CURVES (got 3 and 2)')
      end
    end

    # SMOOTH_CURVE
    # ------------

    describe 'SMOOTH_CURVE(nil, 2)' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'SMOOTH_CURVE([], 2)' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'SMOOTH_CURVE([1, 2], 2)' do
      it('returns [1.5, 1.5]') { expect(result).to eq([1.5, 1.5]) }
    end

    describe 'SMOOTH_CURVE([1, 2], 4)' do
      it('returns [1.5, 1.5]') { expect(result).to eq([1.5, 1.5]) }
    end

    describe 'SMOOTH_CURVE([1, 2, 3, 4, 5, 6], 2)' do
      it('returns [3.5, 1.5, 2.5, 3.5, 4.5, 5.5]') do
        expect(result).to eq([3.5, 1.5, 2.5, 3.5, 4.5, 5.5])
      end
    end

    describe 'SMOOTH_CURVE([1, 2, 3, 4, 5, 6], 3)' do
      it('returns [3, 2, 3, 4, 5, 4]') do
        expect(result).to eq([3, 2, 3, 4, 5, 4])
      end
    end

    describe 'SMOOTH_CURVE([1, 2, 3, 4, 5, 6], 4)' do
      it('returns [3.5, 3, 2.5, 3.5, 4.5, 4') do
        expect(result).to eq([3.5, 3, 2.5, 3.5, 4.5, 4])
      end
    end

    describe 'SMOOTH_CURVE([1, 2, 3, 4, 5, 6], 5)' do
      it('returns [3.4, 3.2, 3.0, 4.0, 3.8, 3.6]') do
        expect(result).to eq([3.4, 3.2, 3.0, 4.0, 3.8, 3.6])
      end
    end

    describe 'SMOOTH_CURVE([1, 2, 3, 4, 5, 6], 6)' do
      it('returns [3.5, 3.5, 3.5, 3.5, 3.5, 3.5]') do
        expect(result).to eq([3.5, 3.5, 3.5, 3.5, 3.5, 3.5])
      end
    end
  end
end
