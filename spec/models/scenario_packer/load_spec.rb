# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioPacker::Load, type: :model do
  let(:scenario_data) do
    {
      area_code:        'nl',
      end_year:         2050,
      private:          false,
      keep_compatible:  true,
      user_values:      { foo: 1.23 },
      balanced_values:  { bar: 4.56 },
      active_couplings: [],
      'user_sortables' => {
        'HeatNetworkOrder' => [
          { 'temperature' => 'ht', 'order' => HeatNetworkOrder.default_order }
        ],
        'ForecastStorageOrder' => { 'order' => ForecastStorageOrder.default_order }
      },
      'user_curves' => {
        'curve_one' => [0, 1, 2, 3],
        'curve_two' => [4, 5, 6, 7]
      }
    }.with_indifferent_access
  end

  subject(:loader) { described_class.new(scenario_data) }
  let(:scenario_instance) { loader.instance_variable_get(:@scenario) }

  describe '#initialize' do
    it 'initializes a new Scenario with correct attributes' do
      expect(scenario_instance).to be_a(Scenario)
      expect(scenario_instance).to be_new_record
      expect(scenario_instance.area_code).to eq 'nl'
      expect(scenario_instance.end_year).to eq 2050
      expect(scenario_instance.private).to be false
      expect(scenario_instance.keep_compatible).to be true
      expect(scenario_instance.user_values).to eq('foo' => 1.23)
      expect(scenario_instance.balanced_values).to eq('bar' => 4.56)
      expect(scenario_instance.active_couplings).to eq []
      expect(scenario_instance.heat_network_orders).to be_empty
      expect { scenario_instance.user_curves }.not_to raise_error
    end
  end

  describe '#create_sortables' do
    before { loader.send(:create_sortables) }

    it 'builds one HeatNetworkOrder' do
      heat_orders = scenario_instance.heat_network_orders
      expect(heat_orders.first.temperature).to eq 'ht'
      expect(heat_orders.first.order).to eq HeatNetworkOrder.default_order
    end

    it 'builds one ForecastStorageOrder' do
      forecast_order = scenario_instance.forecast_storage_order
      expect(forecast_order).to be_a(ForecastStorageOrder)
      expect(forecast_order.order).to eq ForecastStorageOrder.default_order
    end
  end

  describe '#create_curves' do
    before { loader.send(:create_curves) }

    it 'builds UserCurve records with correct keys and data' do
      curve_keys = scenario_instance.user_curves.map(&:key)
      expect(curve_keys).to match_array %w[curve_one curve_two]

      curve_one = scenario_instance.user_curves.find { |c| c.key == 'curve_one' }
      expect(curve_one.curve).to eq [0, 1, 2, 3]
    end
  end

  describe '#scenario' do
    it 'creates associations and persists the Scenario' do
      allow(scenario_instance).to receive(:save!).and_return(true)

      result = loader.scenario

      expect(result).to be(scenario_instance)
      expect(scenario_instance).to have_received(:save!)
      expect(scenario_instance.heat_network_orders.size).to eq 1
      expect(scenario_instance.user_curves.size).to eq 2
    end
  end
end
