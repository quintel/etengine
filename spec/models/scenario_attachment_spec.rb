require 'spec_helper'

describe ScenarioAttachment do

  context 'with all from_other_scenario attributes set' do
    subject do
      ScenarioAttachment.new(
        attachment_key: 'interconnector_1_price_curve',
        other_saved_scenario_id: 1,
        other_scenario_title: 'a',
        other_dataset_key: 'nl',
        other_end_year: 2050
      )
    end

    it { is_expected.to be_valid }
  end

  context 'with some from_other_scenario attributes set' do
    subject do
      ScenarioAttachment.new(
        attachment_key: 'interconnector_1_price_curve',
        other_dataset_key: 'nl',
        other_end_year: 2050
      )
    end

    it { is_expected.to_not be_valid }
  end

  context 'with no from_other_scenario attributes set' do
    subject do
      ScenarioAttachment.new(
        attachment_key: 'interconnector_1_price_curve'
      )
    end

    it { is_expected.to be_valid }
  end
end
