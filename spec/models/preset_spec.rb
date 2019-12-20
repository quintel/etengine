require 'spec_helper'

describe Preset, :etsource_fixture do
  it "initializes" do
    preset = Preset.new(id: 1, user_values: {}, end_year: 2050, area_code: 'nl', foo_bar: 'has no effect')
    expect(preset.id).to          eq(1)
    expect(preset.user_values).to eq({})
    expect(preset.end_year).to    eq(2050)
    expect(preset.area_code).to   eq('nl')
  end

  it "load records" do
    expect(Preset.all.map(&:id).include?(2999)).to be_truthy
  end

  it 'fetches the start_year' do
    expect(Preset.new(area_code: 'nl').start_year).
      to eq(Atlas::Dataset.find(:nl).analysis_year)
  end

  describe "#to_scenario" do
    let(:scenario) { Preset.all.first.to_scenario }

    it 'returns a scenario' do
      expect(scenario).to be_a(Scenario)
    end

    it 'has the same user_values' do
      expect(scenario.user_values).to include foo_demand: 10
    end

    it 'does not create a scaling' do
      expect(scenario.scaler).to be_nil
    end

    describe 'flexibility order' do
      it 'is not saved' do
        expect(scenario.flexibility_order).to be_new_record
      end

      it 'is a default order' do
        expect(scenario.flexibility_order).to be_default
      end
    end

    describe 'heat network order' do
      it 'is not saved' do
        expect(scenario.heat_network_order).to be_new_record
      end

      it 'is a default order' do
        expect(scenario.heat_network_order).to be_default
      end
    end

    context 'with a scaled preset' do
      let(:preset)   { Preset.get(6000) }
      let(:scenario) { Preset.get(6000).to_scenario }

      it 'sets the scenario scaler' do
        expect(scenario.scaler).to be_a(ScenarioScaling)
      end

      it 'creates a new scaler' do
        expect(scenario.scaler.id).to be_nil
      end

      it 'sets the scaling value' do
        expect(scenario.scaler.value).to eq(preset.scaler.value)
        expect(scenario.scaler.base_value).to eq(preset.scaler.base_value)
      end
    end

    context 'when the preset has a flexibility order' do
      let(:preset)   { Preset.get(6001) }
      let(:scenario) { Preset.get(6001).to_scenario }

      it 'sets the flexibility order' do
        expect(scenario.flexibility_order).to be_a(FlexibilityOrder)
      end

      it 'creates a flexibility order' do
        expect(scenario.flexibility_order.id).to be_nil
      end

      it 'sets the flexibility order to be read only' do
        expect(scenario.flexibility_order).to be_readonly
      end

      it 'sets the order value' do
        expect(scenario.flexibility_order.order)
          .to eq(preset.flexibility_order.order)
      end
    end

    context 'when the preset has a heat network order' do
      let(:preset)   { Preset.get(6001) }
      let(:scenario) { Preset.get(6001).to_scenario }

      it 'sets the heat network order' do
        expect(scenario.heat_network_order).to be_a(HeatNetworkOrder)
      end

      it 'creates a heat network order' do
        expect(scenario.heat_network_order.id).to be_nil
      end

      it 'sets the heat network order to be read only' do
        expect(scenario.heat_network_order).to be_readonly
      end

      it 'sets the order value' do
        expect(scenario.heat_network_order.order)
          .to eq(preset.heat_network_order.order)
      end
    end
  end

  describe '.to_active_document' do
    context 'with an unscaled preset' do
      let(:preset) { Preset.get(2999) }

      it 'succeeds' do
        expect { preset.to_active_document }.not_to raise_error
      end

      it 'matches the original' do
        expect(preset.to_active_document.lines.sort).to eq(
          File.read('spec/fixtures/etsource/presets/test.ad').lines.sort
        )
      end
    end

    context 'with a scaled preset' do
      let(:preset) { Preset.get(6000) }

      it 'succeeds' do
        expect { preset.to_active_document }.not_to raise_error
      end

      it 'contains scaling data' do
        expect(preset.to_active_document).to include('scaling.value = 100')
      end

      it 'matches the original' do
        expect(preset.to_active_document.lines.sort).to eq(
          File.read('spec/fixtures/etsource/presets/scaled.ad').lines.sort
        )
      end
    end
  end # .to_active_document

  describe '.from_scenario' do
    let(:preset) { Preset.from_scenario(scenario) }

    context 'with an unscaled scenario' do
      let(:scenario) { FactoryBot.build(:scenario, user_values: { a: 1 }) }

      it 'sets user values' do
        expect(preset.user_values).to eq(scenario.user_values)
      end

      it 'has no scaler' do
        expect(preset.scaler).to be_blank
      end
    end

    context 'with a scaled scenario' do
      let(:scenario) do
        FactoryBot.build(:scenario, user_values: { a: 1 }).tap do |s|
          s.scaler = ScenarioScaling.new(value: 300, base_value: 500)
        end
      end

      it 'sets user values' do
        expect(preset.user_values).to eq(scenario.user_values)
      end

      it 'has a scaler' do
        expect(preset.scaler).not_to be_blank
      end

      it 'sets the scaler values' do
        expect(preset.scaler.attributes).to eq(scenario.scaler.attributes)
      end
    end # with a scaled scenario

    context 'with no flexibility order' do
      let(:scenario) { FactoryBot.build(:scenario, user_values: { a: 1 }) }

      it 'has no flexibility order' do
        expect(preset.flexibility_order).to be_blank
      end
    end # with no flexibility order

    context 'with a default flexibility order' do
      let(:scenario) do
        FactoryBot.build(:scenario, user_values: { a: 1 }).tap do |s|
          s.flexibility_order =
            FlexibilityOrder.new(order: FlexibilityOrder.default_order)
        end
      end

      it 'has no flexibility order' do
        expect(preset.flexibility_order).to be_blank
      end
    end

    context 'with a non-default flexibility order' do
      let(:scenario) do
        FactoryBot.build(:scenario, user_values: { a: 1 }).tap do |s|
          s.flexibility_order =
            FlexibilityOrder.new(order: FlexibilityOrder.default_order.reverse)
        end
      end

      it 'has a flexibility order' do
        expect(preset.flexibility_order).not_to be_blank
      end

      it 'sets the flexibility order values' do
        expect(preset.flexibility_order.order)
          .to eq(FlexibilityOrder.default_order.reverse)
      end
    end

    context 'with a default heat network order' do
      let(:scenario) do
        FactoryBot.build(:scenario, user_values: { a: 1 }).tap do |s|
          s.heat_network_order =
            HeatNetworkOrder.new(order: HeatNetworkOrder.default_order)
        end
      end

      it 'has no heat network order' do
        expect(preset.heat_network_order).to be_blank
      end
    end

    context 'with a non-default heat network order' do
      let(:scenario) do
        FactoryBot.build(:scenario, user_values: { a: 1 }).tap do |s|
          s.heat_network_order =
            HeatNetworkOrder.new(order: HeatNetworkOrder.default_order.reverse)
        end
      end

      it 'has a heat network order' do
        expect(preset.heat_network_order).not_to be_blank
      end

      it 'sets the heat network order values' do
        expect(preset.heat_network_order.order)
          .to eq(HeatNetworkOrder.default_order.reverse)
      end
    end
  end # .from_scenario
end
