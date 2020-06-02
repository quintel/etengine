require 'spec_helper'

describe ScenarioAttachment do
  let(:metadata) do
    {
      other_scenario_id: 1,
      other_saved_scenario_id: 1,
      other_scenario_title: 'a',
      other_dataset_key: 'nl',
      other_end_year: 2050
    }
  end

  context 'with all from_other_scenario attributes set' do
    subject do
      ScenarioAttachment.new(
        metadata.merge(attachment_key: 'interconnector_1_price_curve')
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

  describe '#update_or_remove_metadata' do
    context 'when all metadata is set' do
      let (:attachment) do
        ScenarioAttachment.new(
          metadata.merge(attachment_key: 'interconnector_1_price_curve')
        )
      end
      it 'removes the metadata when no new metadata is supplied' do
        expect { attachment.update_or_remove_metadata({}) }
          .to change {
            attachment.from_other_scenario?
          }.from(true).to(false)
      end

      it 'updates the metadata when new metadata is given' do
        expect { attachment.update_or_remove_metadata(metadata) }
          .not_to change {
            attachment.from_other_scenario?
          }.from(true)
      end
    end

    context 'when no metadata is set' do
      let (:attachment) do
        ScenarioAttachment.new(
          attachment_key: 'interconnector_1_price_curve'
        )
      end

      it 'does nothing when no new metadata is supplied' do
        expect { attachment.update_or_remove_metadata({}) }
          .not_to change {
            attachment.from_other_scenario?
          }.from(false)
      end

      it 'updates the metadata when new metadata is given' do
        expect { attachment.update_or_remove_metadata(metadata) }
          .to change {
            attachment.from_other_scenario?
          }.from(false).to(true)
      end
    end
  end
end
