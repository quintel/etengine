require 'spec_helper'

module Gql::Runtime::Functions
  describe Lookup, :etsource_fixture do
    let(:gql) { Scenario.default.gql(prepare: true) }

    let(:result) do |example|
      gql.query_future(example.metadata[:example_group][:description])
    end

    describe 'CURVE_SET_VARIANTS(weather)' do
      it 'returns ["default", "empty"]' do
        expect(result).to eq(%w[default empty])
      end
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

    describe 'SUM_CURVES([[1, 2], [3, 4], [5, 6]])' do
      it('returns [9, 12]') { expect(result).to eq([9, 12]) }
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

    # WEATHER_PROPERTY
    # ----------------

    describe 'WEATHER_PROPERTY(flh_of_energy_power_wind_turbine_coastal)' do
      it 'returns a value' do
        expect(result).to eq(2350)
      end
    end

    describe 'WEATHER_PROPERTY(invalid)' do
      it 'raises an error' do
        expect { result }.to raise_error(/No row called :invalid/)
      end
    end

    context 'when the weather curve set has no weather_properties.csv' do
      describe 'WEATHER_PROPERTY(flh_of_energy_power_wind_turbine_coastal)' do
        before do
          gql.future_graph.area.weather_curve_set = 'empty'
        end

        it 'raises an error' do
          expect { result }.to raise_error(/No weather_properties.csv found/)
        end
      end
    end
  end
end
