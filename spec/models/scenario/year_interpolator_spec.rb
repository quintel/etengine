require 'spec_helper'

RSpec.describe Scenario::YearInterpolator do
  context 'with a scenario' do
    let(:source) do
      FactoryBot.create(:scenario, {
        id:              99999, # Avoid a collision with a preset ID
        end_year:        2050,
        user_values:     { 'grouped_input_one' => 75 },
        balanced_values: { 'grouped_input_two' => 50 }
      })
    end

    let(:interpolated) { described_class.call(source, 2030) }

    it 'returns a new scenario' do
      expect(interpolated).to be_a(Scenario)
    end

    it 'sets the end year' do
      expect(interpolated.end_year).to eq(2030)
    end

    it 'sets the dataset' do
      expect(interpolated.area_code).to eq('nl')
    end

    it 'interpolates user_values inputs' do
      # start = 100, min = 0, max = 100
      # 100 -> 75 in 39 years
      # = 87.820512821 in 19 years
      expect(interpolated.user_values['grouped_input_one'])
        .to be_within(1e-2).of(87.82)
    end

    it 'interpolates balanced_values inputs' do
      # start = 0, min = 0, max = 100
      # 0 -> 50 in 39 years
      # = 24.358974359 in 19 years
      expect(interpolated.balanced_values['grouped_input_two'])
        .to be_within(1e-2).of(24.35)
    end
  end

  context 'with a scenario containing a non-existant input' do
    let(:source) do
      FactoryBot.create(:scenario, {
        id:          99999, # Avoid a collision with a preset ID
        end_year:    2050,
        user_values: {
          'grouped_input_one' => 75,
          'nope'              => 100,
        }
      })
    end

    let(:interpolated) { described_class.call(source, 2030) }

    it 'keeps valid inputs' do
      expect(interpolated.user_values.keys).to include('grouped_input_one')
    end

    it 'removes the invalid input' do
      expect(interpolated.user_values.keys).not_to include('nope')
    end
  end

  context 'with a scenario containing an enum input' do
    let(:source) do
      FactoryBot.create(:scenario, {
        id: 99999,
        end_year: 2050,
        user_values: {
          'grouped_input_one' => 75,
          'enum' => 'default'
        }
      })
    end

    let(:interpolated) { described_class.call(source, 2030) }

    it 'sets the inputs' do
      expect(interpolated.user_values.keys.sort)
        .to eq(%w[enum grouped_input_one])
    end

    it 'interpolates the numeric inputs' do
      expect(interpolated.user_values['grouped_input_one'])
        .to be_within(1e-2).of(87.82)
    end

    it 'retains the value of the enum input' do
      expect(interpolated.user_values['enum']).to eq('default')
    end
  end

  context 'with a year older than the analysis year' do
    let(:source) do
      FactoryBot.create(:scenario, {
        id:          99999, # Avoid a collision with a preset ID
        end_year:    2050,
        user_values: { 'grouped_input_one' => 75 }
      })
    end

    let(:interpolated) { described_class.call(source, 2010) }

    it 'raises an exception' do
      expect { interpolated }
        .to raise_error(/prior to the dataset analysis year/i)
    end
  end

  context 'with a year after the source scenario end year' do
    let(:source) do
      FactoryBot.create(:scenario, {
        id:          99999, # Avoid a collision with a preset ID
        end_year:    2050,
        user_values: { 'grouped_input_one' => 75 }
      })
    end

    let(:interpolated) { described_class.call(source, 2051) }

    it 'raises an exception' do
      expect { interpolated }.to raise_error(/prior to the original scenario/i)
    end
  end

  context 'with a year the same as the source scenario end year' do
    let(:source) do
      FactoryBot.create(:scenario, {
        id:              99999, # Avoid a collision with a preset ID
        end_year:        2050,
        user_values:     { 'grouped_input_one' => 75 },
        balanced_values: { 'grouped_input_two' => 50 }
      })
    end

    let(:interpolated) { described_class.call(source, 2050) }

    it 'sets user_values inputs' do
      expect(interpolated.user_values).to eq(source.user_values)
    end

    it 'sets balanced_values inputs' do
      expect(interpolated.balanced_values).to eq(source.balanced_values)
    end
  end

  context 'when the scenario has a heat network order' do
    let(:source) do
      FactoryBot.create(:scenario, {
        id:          99999, # Avoid a collision with a preset ID
        end_year:    2050,
        user_values: { 'grouped_input_one' => 75 }
      })
    end

    let(:techs) do
      HeatNetworkOrder.default_order.shuffle
    end

    let(:interpolated) { described_class.call(source, 2040) }

    before do
      HeatNetworkOrder.create!(scenario: source, order: techs)
    end

    it 'creates a heat network order for the interpolated scenario' do
      expect(interpolated.heat_network_order).not_to be_nil
    end

    it 'does not reuse the original heat network order' do
      expect(interpolated.heat_network_order.id)
        .not_to eq(source.heat_network_order.id)
    end

    it 'copies the heat network order attributes' do
      expect(interpolated.heat_network_order.order).to eq(techs)
    end
  end
end
