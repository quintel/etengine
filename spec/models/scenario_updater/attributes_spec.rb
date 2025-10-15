# frozen_string_literal: true

require 'spec_helper'

describe ScenarioUpdater::Attributes, :etsource_fixture do
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:params) { {} }
  let(:updater) { described_class.new(scenario, params, nil) }

  describe '#attributes_to_apply' do
    context 'with no scenario parameters' do
      let(:params) { {} }

      it 'returns an empty hash with metadata' do
        expect(updater.attributes_to_apply).to eq('metadata' => scenario.metadata)
      end
    end

    context 'with parameters, but no user values' do
      before do
        scenario.update!(
          end_year: 2035,
          user_values: { 'foo_demand' => 1.0 }
        )
      end

      let(:params) { { autobalance: true, scenario: { keep_compatible: true } } }

      it 'includes the scenario attributes' do
        expect(updater.attributes_to_apply).to include('keep_compatible' => true)
      end

      it 'excludes area_code' do
        expect(updater.attributes_to_apply).not_to have_key('area_code')
      end

      it 'excludes end_year' do
        expect(updater.attributes_to_apply).not_to have_key('end_year')
      end

      it 'excludes user_values' do
        expect(updater.attributes_to_apply).not_to have_key('user_values')
      end

      it 'excludes set_preset_roles' do
        expect(updater.attributes_to_apply).not_to have_key('set_preset_roles')
      end

      it 'includes metadata' do
        expect(updater.attributes_to_apply).to have_key('metadata')
      end
    end

    context 'with multiple scenario attributes' do
      let(:params) do
        {
          scenario: {
            title: 'New Title',
            keep_compatible: true,
            private: false,
            area_code: 'de', # Should be excluded
            end_year: 2040, # Should be excluded
            user_values: { 'foo' => 1 } # Should be excluded
          }
        }
      end

      it 'includes title' do
        expect(updater.attributes_to_apply).to include('title' => 'New Title')
      end

      it 'includes keep_compatible' do
        expect(updater.attributes_to_apply).to include('keep_compatible' => true)
      end

      it 'includes private' do
        expect(updater.attributes_to_apply).to include('private' => false)
      end

      it 'excludes area_code' do
        expect(updater.attributes_to_apply).not_to have_key('area_code')
      end

      it 'excludes end_year' do
        expect(updater.attributes_to_apply).not_to have_key('end_year')
      end

      it 'excludes user_values' do
        expect(updater.attributes_to_apply).not_to have_key('user_values')
      end
    end
  end

  describe 'metadata validation' do
    context 'with no metadata' do
      let(:params) { { scenario: {} } }

      it 'is valid' do
        expect(updater).to be_valid
      end
    end

    context 'with metadata within size limit' do
      let(:params) do
        {
          scenario: {
            metadata: { "ctm_scenario_id" => 12_345, "kittens" => "mew" }
          }
        }
      end

      it 'is valid' do
        expect(updater).to be_valid
      end

      it 'includes the metadata in attributes_to_apply' do
        expect(updater.attributes_to_apply['metadata']).to eq(
          "ctm_scenario_id" => 12_345,
          "kittens" => "mew"
        )
      end
    end

    context 'with empty metadata' do
      let(:params) do
        {
          scenario: { metadata: {} }
        }
      end

      it 'is valid' do
        expect(updater).to be_valid
      end

      it 'includes empty metadata in attributes_to_apply' do
        expect(updater.attributes_to_apply['metadata']).to eq({})
      end
    end

    context 'with nil metadata in params' do
      let(:params) do
        {
          scenario: { metadata: nil }
        }
      end

      it 'is valid' do
        expect(updater).to be_valid
      end

      it 'includes nil metadata in attributes_to_apply' do
        expect(updater.attributes_to_apply['metadata']).to be_nil
      end
    end

    context 'when scenario already has metadata' do
      before do
        scenario.metadata = { "existing" => "data" }
        scenario.save!
      end

      context 'and no new metadata is provided' do
        let(:params) { { scenario: { title: 'Updated' } } }

        it 'preserves existing metadata' do
          expect(updater.attributes_to_apply['metadata']).to eq("existing" => "data")
        end
      end

      context 'and new metadata is provided' do
        let(:params) do
          {
            scenario: { metadata: { "new" => "metadata" } }
          }
        end

        it 'uses the new metadata' do
          expect(updater.attributes_to_apply['metadata']).to eq("new" => "metadata")
        end

        it 'does not merge with existing metadata' do
          expect(updater.attributes_to_apply['metadata']).not_to have_key("existing")
        end
      end
    end
  end

  describe '#valid?' do
    context 'with valid attributes' do
      let(:params) do
        {
          scenario: {
            title: 'Test Scenario',
            keep_compatible: true
          }
        }
      end

      it 'returns true' do
        expect(updater).to be_valid
      end

      it 'has no errors' do
        updater.valid?
        expect(updater.errors).to be_blank
      end
    end
  end
end
