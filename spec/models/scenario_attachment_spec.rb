# frozen_string_literal: true

require 'spec_helper'

describe ScenarioAttachment do
  let(:metadata) do
    {
      source_scenario_id: 1,
      source_saved_scenario_id: 1,
      source_scenario_title: 'a',
      source_dataset_key: 'nl',
      source_end_year: 2050
    }
  end

  context 'with all source scenario attributes set' do
    subject do
      described_class.new(
        metadata.merge(key: 'interconnector_1_price_curve')
      )
    end

    it { is_expected.to be_valid }
  end

  context 'with some source scenario attributes set' do
    subject do
      described_class.new(
        key: 'interconnector_1_price_curve',
        source_dataset_key: 'nl',
        source_end_year: 2050
      )
    end

    it { is_expected.not_to be_valid }
  end

  context 'with no source scenario attributes set' do
    subject do
      described_class.new(
        key: 'interconnector_1_price_curve'
      )
    end

    it { is_expected.to be_valid }
  end

  context 'when an interconnector_1_price curve attachment already exists' do
    before do
      described_class.create!(
        scenario_id: 1,
        key: 'interconnector_1_price_curve'
      )
    end

    context 'with a new "interconnector_1_price_curve" attachment' do
      let(:attachment) do
        described_class.new(
          scenario_id: 1,
          key: 'interconnector_1_price_curve'
        )
      end

      it 'is invalid' do
        expect(attachment).not_to be_valid
      end

      it 'has an error on key' do
        attachment.valid?

        expect(attachment.errors[:key])
          .to include('already exists for this scenario')
      end
    end

    context 'with a new "interconnector_1_price_curve" attachment for a ' \
            'different scenario' do
      it 'is valid' do
        attachment = described_class.new(
          scenario_id: 2,
          key: 'interconnector_1_price_curve'
        )

        expect(attachment).to be_valid
      end
    end

    context 'with a new "interconnector_2_price_curve" attachment' do
      it 'is valid' do
        attachment = described_class.new(
          scenario_id: 2,
          key: 'interconnector_2_price_curve'
        )

        expect(attachment).to be_valid
      end
    end
  end

  describe '#update_or_remove_metadata' do
    context 'when all metadata is set' do
      let(:attachment) do
        described_class.new(
          metadata.merge(key: 'interconnector_1_price_curve')
        )
      end

      it 'removes the metadata when no new metadata is supplied' do
        expect { attachment.update_or_remove_metadata({}) }
          .to change(attachment, :source_scenario?)
          .from(true).to(false)
      end

      it 'updates the metadata when new metadata is given' do
        expect { attachment.update_or_remove_metadata(metadata) }
          .not_to change(attachment, :source_scenario?)
          .from(true)
      end
    end

    context 'when no metadata is set' do
      let(:attachment) do
        described_class.new(
          key: 'interconnector_1_price_curve'
        )
      end

      it 'does nothing when no new metadata is supplied' do
        expect { attachment.update_or_remove_metadata({}) }
          .not_to change(attachment, :source_scenario?)
          .from(false)
      end

      it 'updates the metadata when new metadata is given' do
        expect { attachment.update_or_remove_metadata(metadata) }
          .to change(attachment, :source_scenario?)
          .from(false).to(true)
      end
    end
  end
end
