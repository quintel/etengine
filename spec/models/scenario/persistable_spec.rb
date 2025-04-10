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
