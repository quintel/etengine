# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserCurve do
  let(:scenario) { create(:scenario) }

  describe 'core functionality' do
    let(:curve_data) { [0.0, 1.0, 2.0, 3.0] }

    it 'serializes and deserializes to a Merit::Curve' do
      user_curve = create(
        :user_curve,
        scenario:,
        key: 'some_curve',
        curve: Merit::Curve.new(curve_data, 8760, 0.0)
      )

      user_curve.reload
      expect(user_curve.curve).to be_a(Merit::Curve)
      expect(user_curve.curve.to_a).to eq(curve_data + [0.0] * (8760 - 4))
    end

    it 'validates uniqueness of key per scenario' do
      create(:user_curve, scenario:, key: 'duplicate_curve')
      duplicate = build(:user_curve, scenario:, key: 'duplicate_curve')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:key]).to include('has already been taken')
    end
  end

  describe 'metadata handling' do
    let(:metadata) do
      {
        source_scenario_id: 1,
        source_scenario_title: 'Imported Curve',
        source_saved_scenario_id: 123,
        source_dataset_key: 'nl',
        source_end_year: 2050
      }
    end

    it 'returns true when all source scenario metadata is set' do
      user_curve = create(:user_curve, scenario:, **metadata)

      expect(user_curve.source_scenario?).to be(true)
    end

    it 'returns false when only partial metadata is set' do
      user_curve = build(:user_curve, scenario:, source_scenario_id: 1)

      expect(user_curve).not_to be_valid
      expect(user_curve.errors[:base])
        .to include('All metadata needs to be set for curves imported from another scenario')
    end

    it 'returns false when no metadata is set' do
      user_curve = build(:user_curve, scenario:)

      expect(user_curve.source_scenario?).to be(false)
    end

    it 'clears metadata when passed nil to update_or_remove_metadata' do
      user_curve = create(:user_curve, scenario:, **metadata)

      user_curve.update_or_remove_metadata(nil)

      expect(user_curve.source_scenario?).to be(false)
      expect(user_curve.metadata_json).to eq({})
    end

    it 'updates metadata with update_or_remove_metadata' do
      user_curve = create(:user_curve, scenario:)
      new_meta = {
        source_scenario_id: 42,
        source_scenario_title: 'Wind import',
        source_saved_scenario_id: 999,
        source_dataset_key: 'de',
        source_end_year: 2040
      }

      user_curve.update_or_remove_metadata(new_meta)

      expect(user_curve.source_scenario?).to be(true)
      expect(user_curve.metadata_json).to eq(new_meta)
    end
  end
end
