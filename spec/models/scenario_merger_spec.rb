require 'spec_helper'

describe ScenarioMerger do
  let(:scenario_one) do
    FactoryGirl.build(:scenario, {
      user_values:     { 'grouped_input_one' => 25.0 },
      balanced_values: { 'grouped_input_two' => 75.0 }
    })
  end

  let(:scenario_two) do
    FactoryGirl.build(:scenario, {
      user_values:     { 'grouped_input_one' => 75.0 },
      balanced_values: { 'grouped_input_two' => 25.0 }
    })
  end

  let(:merger) { ScenarioMerger.new([[scenario_one, 3], [scenario_two, 1]]) }
  let(:merged) { merger.merged_scenario }

  context 'given two scenarios' do
    it 'is valid' do
      expect(merger).to be_valid
    end

    it 'returns a valid new scenario' do
      expect(merged).to be_valid
    end

    it 'assigns user values' do
      # Input value is 37.5 since 75% weight is applied to the first scenario
      # above (weight=3 while scenario two is weight=1).
      expect(merged.user_values).to eq('grouped_input_one' => 37.5)
    end

    it 'balances share groups' do
      expect(merged.balanced_values).to eq('grouped_input_two' => 62.5)
    end

    it 'assigns the area code' do
      expect(merged.area_code).to eq(scenario_one.area_code)
    end

    it 'assigns the end year' do
      expect(merged.end_year).to eq(scenario_one.end_year)
    end
  end # given two scenarios

  context 'given a scaled scenario' do
    before do
      scenario_one.scaler = ScenarioScaling.new
    end

    it 'is not valid' do
      expect(merger).to_not be_valid
    end

    it 'has an error about scaling' do
      expect(merger.errors_on(:base)).
        to include('Cannot merge scenarios which have been scaled down')
    end
  end # given a scaled scenario

  context 'given scenarios with different end years' do
    before do
      scenario_one.end_year = 2015
    end

    it 'is not valid' do
      expect(merger).to_not be_valid
    end

    it 'has an error about end years' do
      expect(merger.errors_on(:base)).
        to include('One or more scenarios have differing end years')
    end
  end # given scenarios with different end years

  context 'given scenarios with different areas' do
    before do
      scenario_one.area_code = 'uk'
    end

    it 'is not valid' do
      expect(merger).to_not be_valid
    end

    it 'has an error about areas' do
      expect(merger.errors_on(:base)).
        to include('One or more scenarios have differing area codes')
    end
  end # given scenarios with different areas

  context 'given one scenario' do
    let(:merger) do
      scenario_one.save!
      ScenarioMerger.new([[scenario_one, 50]])
    end

    it 'returns a cloned copy of the original' do
      expect(merged.preset_scenario_id).to eq(scenario_one.id)
    end

    it 'copies the user values from the original' do
      expect(merged.user_values).to eq(scenario_one.user_values)
    end

    it 'copies the balanaced values from the original' do
      expect(merged.balanced_values).to eq(scenario_one.balanced_values)
    end

    it 'copies the end year from the original' do
      expect(merged.end_year).to eq(scenario_one.end_year)
    end

    it 'copies the area code from the original' do
      expect(merged.area_code).to eq(scenario_one.area_code)
    end
  end # given one scenario

  context 'given no scenarios' do
    it 'raises an error' do
      expect { ScenarioMerger.new([]) }
        .to raise_error('Cannot create a ScenarioMerger with no scenarios')
    end
  end # given no scenarios

  context 'given nil' do
    it 'raises an error' do
      expect { ScenarioMerger.new(nil) }
        .to raise_error('Cannot create a ScenarioMerger with no scenarios')
    end
  end # given nil
end # ScenarioMerger
