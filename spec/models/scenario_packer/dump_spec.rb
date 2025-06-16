# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioPacker::Dump, type: :model do
  subject(:dumper) { described_class.new(scenario) }

  let!(:scenario) do
    scenario = create(
      :scenario,
      area_code:       'nl',
      end_year:        2040,
      private:         false,
      keep_compatible: true
    )

    scenario.update!(
      user_values:      { 'foo' => 9.87 },
      balanced_values:  { 'bar' => 6.54 },
      active_couplings: []
    )

    create(
      :heat_network_order,
      scenario:,
      temperature: 'ht',
      order:       HeatNetworkOrder.default_order
    )

    scenario.create_forecast_storage_order!(order: ForecastStorageOrder.default_order)

    create(:user_curve, scenario:, key: 'c1', curve: [1, 2, 3])
    create(:user_curve, scenario:, key: 'c2', curve: [4, 5, 6])

    scenario
  end
  let(:json_data)  { dumper.as_json }
  let(:data)       { json_data.with_indifferent_access }

  it 'exposes the basic scenario attributes' do
    expected_attributes = {
      'area_code'        => 'nl',
      'end_year'         => 2040,
      'private'          => false,
      'keep_compatible'  => true,
      'user_values'      => { 'foo' => 9.87 },
      'balanced_values'  => { 'bar' => 6.54 },
      'active_couplings' => []
    }

    actual_attributes = json_data.slice(*expected_attributes.keys)

    expect(actual_attributes).to eq(expected_attributes)
  end

  it 'serializes heat_network_orders under user_sortables as an Array' do
    serialized_heat_orders = data[:user_sortables][HeatNetworkOrder]

    expect(serialized_heat_orders).to be_an(Array)
    expect(serialized_heat_orders.first['temperature']).to eq('ht')
    expect(serialized_heat_orders.first['order']).to eq(HeatNetworkOrder.default_order)
  end

  it 'serializes forecast_storage_order under user_sortables as a Hash' do
    serialized_forecast_order = data[:user_sortables][ForecastStorageOrder]

    expect(serialized_forecast_order).to be_a(Hash)
    expect(serialized_forecast_order['order']).to eq(ForecastStorageOrder.default_order)
  end

  it 'renders user_curves as plain arrays' do
    expect(data[:user_curves]).to eq({
      'c1' => [1, 2, 3],
      'c2' => [4, 5, 6]
    })
  end

  it 'does not include unsaved sortables' do
    scenario.heat_network_orders.build(
      temperature: 'mt',
      order: HeatNetworkOrder.default_order
    )

    serialized_orders = described_class
      .new(scenario)
      .as_json
      .with_indifferent_access
      .dig(:user_sortables, HeatNetworkOrder) || []

    temperatures = serialized_orders.map { |order| order['temperature'] }

    expect(temperatures).not_to include('mt')
  end
end
