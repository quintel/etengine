# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioJsonSerialization, type: :model do
  let(:scenario) { FactoryBot.create(:scenario) }

  describe '#serialize_sortables' do
    context 'when scenario has no sortables' do
      it 'returns an empty hash' do
        expect(scenario.serialize_sortables).to eq({})
      end
    end

    context 'when scenario has a ForecastStorageOrder' do
      let!(:forecast_order) do
        scenario.create_forecast_storage_order(
          order: ForecastStorageOrder.default_order
        )
      end

      it 'serializes the forecast storage order' do
        result = scenario.serialize_sortables

        expect(result).to have_key(ForecastStorageOrder)
        expect(result[ForecastStorageOrder]).to be_a(Hash)
        expect(result[ForecastStorageOrder][:order]).to eq(ForecastStorageOrder.default_order)
      end
    end

    context 'when scenario has HeatNetworkOrders' do
      let!(:ht_order) do
        scenario.heat_network_orders.create(
          temperature: 'ht',
          order: HeatNetworkOrder.default_order
        )
      end

      let!(:mt_order) do
        scenario.heat_network_orders.create(
          temperature: 'mt',
          order: HeatNetworkOrder.default_order
        )
      end

      it 'aggregates heat network orders into an array' do
        result = scenario.serialize_sortables

        expect(result).to have_key(HeatNetworkOrder)
        expect(result[HeatNetworkOrder]).to be_an(Array)
        expect(result[HeatNetworkOrder].size).to eq(2)
      end

      it 'includes temperature attribute in each heat network order' do
        result = scenario.serialize_sortables

        ht = result[HeatNetworkOrder].find { |o| o[:temperature] == 'ht' }
        mt = result[HeatNetworkOrder].find { |o| o[:temperature] == 'mt' }

        expect(ht).to be_present
        expect(mt).to be_present
        expect(ht[:order]).to eq(HeatNetworkOrder.default_order)
        expect(mt[:order]).to eq(HeatNetworkOrder.default_order)
      end
    end

    context 'when scenario has mixed sortables' do
      let!(:forecast_order) do
        scenario.create_forecast_storage_order(
          order: ForecastStorageOrder.default_order
        )
      end

      let!(:ht_order) do
        scenario.heat_network_orders.create(
          temperature: 'ht',
          order: HeatNetworkOrder.default_order
        )
      end

      it 'serializes both types correctly' do
        result = scenario.serialize_sortables

        expect(result).to have_key(ForecastStorageOrder)
        expect(result).to have_key(HeatNetworkOrder)

        expect(result[ForecastStorageOrder]).to be_a(Hash)
        expect(result[HeatNetworkOrder]).to be_an(Array)
        expect(result[HeatNetworkOrder].size).to eq(1)
      end
    end

    context 'when sortable is not persisted' do
      it 'excludes non-persisted sortables' do
        scenario.build_forecast_storage_order(
          order: ForecastStorageOrder.default_order
        )

        result = scenario.serialize_sortables

        expect(result).to be_empty
      end
    end
  end

  describe '#serialize_curves' do
    context 'when scenario has no curves' do
      it 'returns an empty hash' do
        expect(scenario.serialize_curves).to eq({})
      end
    end

    context 'when scenario has user curves' do
      let!(:curve_one) do
        scenario.user_curves.create(
          key: 'curve_one',
          curve: [0, 1, 2, 3]
        )
      end

      let!(:curve_two) do
        scenario.user_curves.create(
          key: 'curve_two',
          curve: [4, 5, 6, 7]
        )
      end

      it 'serializes curves as a hash keyed by curve name' do
        result = scenario.serialize_curves

        expect(result).to have_key('curve_one')
        expect(result).to have_key('curve_two')
      end

      it 'converts curves to arrays' do
        result = scenario.serialize_curves

        expect(result['curve_one']).to eq([0, 1, 2, 3])
        expect(result['curve_two']).to eq([4, 5, 6, 7])
      end
    end
  end
end
