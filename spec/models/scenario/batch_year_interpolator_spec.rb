require 'spec_helper'

RSpec.describe Scenario::BatchYearInterpolator do
  let(:scenario_2030) do
    FactoryBot.create(:scenario, {
      id: 99990,
      end_year: 2030,
      user_values: { 'grouped_input_one' => 50.0 }
    })
  end

  let(:scenario_2040) do
    FactoryBot.create(:scenario, {
      id: 99991,
      end_year: 2040,
      user_values: { 'grouped_input_one' => 75.0 }
    })
  end

  let(:scenario_2050) do
    FactoryBot.create(:scenario, {
      id: 99992,
      end_year: 2050,
      user_values: { 'grouped_input_one' => 100.0 }
    })
  end

  let(:interpolated) { result.value! }

  context 'with valid scenarios and target years' do
    describe 'when scenario_ids are provided in sequential order' do
      let(:result) do
        described_class.call(
          scenario_ids: [scenario_2030.id, scenario_2040.id, scenario_2050.id],
          end_years: [2035, 2045]
        )
      end

      it 'returns success' do
        expect(result).to be_success
      end

      it 'returns two interpolated scenarios' do
        expect(interpolated.length).to eq(2)
      end

      it 'creates a scenario for year 2035' do
        expect(interpolated[0].end_year).to eq(2035)
      end

      it 'creates a scenario for year 2045' do
        expect(interpolated[1].end_year).to eq(2045)
      end

      it 'interpolates the 2035 scenario between 2030 and 2040' do
        # 50 -> 75 in 10 years
        # = 62.5 in 5 years
        expect(interpolated[0].user_values['grouped_input_one'])
          .to be_within(1e-2).of(62.5)
      end

      it 'interpolates the 2045 scenario between 2040 and 2050' do
        # 75 -> 100 in 10 years
        # = 87.5 in 5 years
        expect(interpolated[1].user_values['grouped_input_one'])
          .to be_within(1e-2).of(87.5)
      end
    end

    describe 'when scenario_ids are provided in random order' do
      let(:result) do
        described_class.call(
          scenario_ids: [scenario_2050.id, scenario_2030.id, scenario_2040.id],
          end_years: [2035]
        )
      end

      it 'returns success' do
        expect(result).to be_success
      end

      it 'creates a scenario for year 2035' do
        expect(interpolated[0].end_year).to eq(2035)
      end

      it 'interpolates the 2035 scenario between 2030 and 2040' do
        # 50 -> 75 in 10 years
        #= 62.5 in 5 years
        expect(interpolated[0].user_values['grouped_input_one'])
          .to be_within(1e-2).of(62.5)
      end
    end
  end

  context 'with fewer than 2 scenarios' do
    let(:result) do
      described_class.call(
        scenario_ids: [scenario_2050.id],
        end_years: [2035]
      )
    end

    it 'returns failure' do
      expect(result).to be_failure
    end

    it 'includes an error about minimum scenarios' do
      expect(result.failure[:scenario_ids]).to include('must contain at least 2 scenarios')
    end
  end

  context 'with empty end_years' do
    let(:result) do
      described_class.call(
        scenario_ids: [scenario_2030.id, scenario_2050.id],
        end_years: []
      )
    end

    it 'returns failure' do
      expect(result).to be_failure
    end

    it 'includes an error about end_years' do
      expect(result.failure[:end_years]).to include('must be filled')
    end
  end

  context 'with a target year before the earliest scenario end_year but after start_year' do
    let(:result) do
      described_class.call(
        scenario_ids: [scenario_2030.id, scenario_2050.id],
        end_years: [2020]
      )
    end

    it 'returns success' do
      expect(result).to be_success
    end

    it 'creates an interpolated scenario for 2020' do
      expect(interpolated[0].end_year).to eq(2020)
    end

    it 'interpolates using the first scenario without a start_scenario_id' do
      # start_year is 2011, end_year is 2030
      # grouped_input_one: start=100, target=50 over 19 years
      # At year 2020 (9 years elapsed): 100 + ((50-100)/19)*9 = 100 - 23.68 = 76.32
      expect(interpolated[0].user_values['grouped_input_one'])
        .to be_within(1e-2).of(76.32)
    end
  end

  context 'with a target year before or equal to the first scenario start_year' do
    let(:result) do
      described_class.call(
        scenario_ids: [scenario_2030.id, scenario_2050.id],
        end_years: [2011]  # start_year is 2011
      )
    end

    it 'returns failure' do
      expect(result).to be_failure
    end

    it 'includes an error about the target year' do
      expect(result.failure[:end_years].first).to match(/must be posterior to the first scenario start year/)
    end
  end

  context 'with a target year after the latest scenario' do
    let(:result) do
      described_class.call(
        scenario_ids: [scenario_2030.id, scenario_2050.id],
        end_years: [2055]
      )
    end

    it 'returns failure' do
      expect(result).to be_failure
    end

    it 'includes an error about the target year' do
      expect(result.failure[:end_years].first).to match(/must be prior to the latest scenario end year/)
    end
  end

  context 'with scenarios having different area codes' do
    let(:scenario_nl) do
      FactoryBot.create(:scenario, { id: 99990, end_year: 2030, area_code: 'nl' })
    end

    let(:scenario_de) do
      FactoryBot.create(:scenario, { id: 99991, end_year: 2050, area_code: 'de' })
    end

    let(:result) do
      described_class.call(
        scenario_ids: [scenario_nl.id, scenario_de.id],
        end_years: [2040]
      )
    end

    it 'returns failure' do
      expect(result).to be_failure
    end

    it 'includes an error about area codes' do
      expect(result.failure[:scenario_ids].first).to match(/same area code/)
    end
  end

  context 'with a non-existent scenario ID' do
    let(:result) do
      described_class.call(
        scenario_ids: [scenario_2050.id, 999999],
        end_years: [2040]
      )
    end

    it 'returns failure' do
      expect(result).to be_failure
    end

    it 'includes an error about missing scenarios' do
      expect(result.failure[:scenario_ids].first).to match(/not found/)
    end
  end

  context 'with a scaled scenario' do
    let(:scenario_scaled) do
      scenario = FactoryBot.create(:scenario, {
        id: 99993,
        end_year: 2050,
        user_values: { 'grouped_input_one' => 100.0 },
        scaler: ScenarioScaling.new(
          area_attribute: 'present_number_of_residences',
          value:          1000
        )
      })
    end

    let(:result) do
      described_class.call(
        scenario_ids: [scenario_2030.id, scenario_scaled.id],
        end_years: [2040]
      )
    end

    it 'returns failure' do
      expect(result).to be_failure
    end

    it 'includes an error about scaled scenarios' do
      expect(result.failure[:scenario_ids].first).to match(/cannot interpolate scaled scenarios/)
    end
  end
end
