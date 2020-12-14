# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'a valid CurveHandler::AttachService' do
  it 'is valid' do
    expect(service).to be_valid
  end

  it 'attaches the curve' do
    expect { service.call }
      .to change { scenario.reload.attachments.count }
      .from(0).to(1)
  end
end

RSpec.describe CurveHandler::AttachService do
  let(:file) { fixture_file_upload('files/price_curve.csv', 'text/csv') }
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:metadata) { {} }

  let(:service) { described_class.new(config, file, scenario, metadata) }

  describe 'when uploading a generic curve' do
    let(:config) { CurveHandler::Config.new(:generic, :generic) }

    include_examples 'a valid CurveHandler::AttachService'
  end

  describe 'when uploading a generic curve with metadata' do
    let(:config) { CurveHandler::Config.new(:generic, :generic) }

    let(:metadata) do
      {
        source_scenario_id: scenario.id,
        source_scenario_title: 'hello',
        source_saved_scenario_id: 1,
        source_dataset_key: 'nl',
        source_end_year: 2050
      }
    end

    include_examples 'a valid CurveHandler::AttachService'

    it 'sets the metadata on the attachment' do
      expect(service.call.metadata_json).to eq(
        source_scenario_id: scenario.id,
        source_scenario_title: 'hello',
        source_saved_scenario_id: 1,
        source_dataset_key: 'nl',
        source_end_year: 2050
      )
    end
  end

  describe 'when attaching a curve with a full_load_hours reducer' do
    let(:config) do
      CurveHandler::Config.new(:generic, :generic, :full_load_hours, %w[i1 i2])
    end

    # Asserts that the original scenario values are not overwritten.
    let(:scenario) { FactoryBot.create(:scenario, user_values: { 'orig' => 1.0 }) }

    include_examples 'a valid CurveHandler::AttachService'

    it 'sets the scenario input value with the reduced value' do
      # The 6570.0 comes from running CurveHandler::Reducers::FullLoadHours on the curve.
      expect { service.call }
        .to change { scenario.reload.user_values }
        .from({ 'orig' => 1.0 }).to({ 'i1' => 6570.0, 'i2' => 6570.0, 'orig' => 1.0 })
    end
  end
end
