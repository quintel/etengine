require 'spec_helper'

RSpec.describe Scenario::Persistable do
  let(:scenario_class) { Class.new { include Scenario::Persistable } }
  let(:scenario) { scenario_class.new }

  describe '#copy_scenario_state' do
    let(:preset) { create(:scenario) }
    let(:new_scenario) { create(:scenario, user_values: {}) }

    before do
      new_scenario.extend(Scenario::Persistable)
      new_scenario.copy_scenario_state(preset)
    end

    context 'when the preset has a scaler' do
      let(:preset) { create(:scaled_scenario) }

      it 'copies the scaler to the new scenario' do
        expect(new_scenario.scaler).not_to be_nil
        expect(new_scenario.scaler.area_attribute).to eq(preset.scaler.area_attribute)
        expect(new_scenario.scaler.value).to eq(preset.scaler.value)
      end

      it 'creates a new scaler record, not the same one' do
        expect(new_scenario.scaler).not_to eq(preset.scaler)
      end
    end

    context 'when the new scenario already has a scaler' do
      let(:existing_scaler) do
        ScenarioScaling.new(
          area_attribute: 'present_number_of_residences',
          base_value: 8_000_000.0,
          has_agriculture: true,
          has_energy: true,
          has_industry: false,
          value: 200.0
        )
      end
      let(:preset) { create(:scaled_scenario) }
      let(:new_scenario) { create(:scenario, user_values: {}, scaler: existing_scaler) }

      it 'does not overwrite the existing scaler' do
        expect(new_scenario.scaler.value).to eq(200.0)
      end
    end

    it 'copies user values from preset' do
      expect(new_scenario.user_values).to include(preset.user_values)
    end

    it 'copies balanced values if present' do
      if preset.balanced_values.present?
        expect(new_scenario.balanced_values).to include(preset.balanced_values)
      end
    end

    it 'copies active couplings' do
      expect(new_scenario.active_couplings).to eq(preset.active_couplings)
    end

    it 'copies end_year and area_code' do
      expect(new_scenario.end_year).to eq(preset.end_year)
      expect(new_scenario.area_code).to eq(preset.area_code)
    end

    it 'clones forecast_storage_order if present' do
      if preset.forecast_storage_order
        expect(new_scenario.forecast_storage_order).not_to eq(preset.forecast_storage_order)
        expect(new_scenario.forecast_storage_order.attributes.except('id', 'scenario_id')).to eq(
          preset.forecast_storage_order.attributes.except('id', 'scenario_id')
        )
      end
    end

    it 'clones households_space_heating_producer_order if present' do
      if preset.households_space_heating_producer_order
        expect(new_scenario.households_space_heating_producer_order).not_to eq(preset.households_space_heating_producer_order)
        expect(new_scenario.households_space_heating_producer_order.attributes.except('id', 'scenario_id')).to eq(
          preset.households_space_heating_producer_order.attributes.except('id', 'scenario_id')
        )
      end
    end

    it 'clones hydrogen_supply_order if present' do
      if preset.hydrogen_supply_order
        expect(new_scenario.hydrogen_supply_order).not_to eq(preset.hydrogen_supply_order)
        expect(new_scenario.hydrogen_supply_order.attributes.except('id', 'scenario_id')).to eq(
          preset.hydrogen_supply_order.attributes.except('id', 'scenario_id')
        )
      end
    end

    it 'clones hydrogen_demand_order if present' do
      if preset.hydrogen_demand_order
        expect(new_scenario.hydrogen_demand_order).not_to eq(preset.hydrogen_demand_order)
        expect(new_scenario.hydrogen_demand_order.attributes.except('id', 'scenario_id')).to eq(
          preset.hydrogen_demand_order.attributes.except('id', 'scenario_id')
        )
      end
    end

    it 'clones attachments if present' do
      if preset.attachments.any?
        expect(new_scenario.attachments.count).to eq(preset.attachments.count)
      end
    end

    it 'clones user curves if present' do
      if preset.user_curves.any?
        expect(new_scenario.user_curves.count).to eq(preset.user_curves.count)
      end
    end

    it 'clones heat network orders if present' do
      if preset.heat_network_orders.any?
        expect(new_scenario.heat_network_orders.count).to eq(preset.heat_network_orders.count)
      end
    end
  end
end
