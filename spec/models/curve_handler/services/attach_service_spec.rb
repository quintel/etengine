# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'a valid CurveHandler::Services::AttachService' do
  it 'is valid' do
    expect(service).to be_valid
  end

  it 'creates or updates a UserCurve record' do
    expect { service.call }
      .to change { scenario.user_curves.count }
      .from(0).to(1)
  end
end

RSpec.describe CurveHandler::Services::AttachService do
  let(:file) { fixture_file_upload('price_curve.csv', 'text/csv') }
  let(:scenario) { FactoryBot.create(:scenario) }
  let(:metadata) { {} }

  let(:service) { described_class.new(config, file, scenario, metadata) }

  describe 'when uploading a generic curve' do
    let(:config) { CurveHandler::Config.new(:generic, :generic) }

    include_examples 'a valid CurveHandler::Services::AttachService'

    it 'saves the sanitized curve in the UserCurve' do
      curve = service.call.curve
      expect(curve).to be_a(Merit::Curve)
      expect(curve.length).to eq(8760)
      expect(curve.get(0)).to be_a(Float)
    end
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

    include_examples 'a valid CurveHandler::Services::AttachService'

    it 'sets the metadata on the UserCurve' do
      user_curve = service.call
      expect(user_curve.metadata_json).to eq(metadata)
    end
  end

  describe 'when attaching a curve with a full_load_hours reducer' do
    let(:file) { fixture_file_upload('capacity_curve.csv', 'text/csv') }

    let(:config) do
      CurveHandler::Config.new(:generic, :capacity_profile, :full_load_hours, %w[i1 i2])
    end

    # Asserts that the original scenario values are not overwritten.
    let(:scenario) { FactoryBot.create(:scenario, user_values: { 'orig' => 1.0 }) }

    before do
      # Skip clamping of values and just set the value.
      allow(scenario).to receive(:update_input_clamped) do |key, value|
        scenario.user_values[key] = value
      end
    end

    include_examples 'a valid CurveHandler::Services::AttachService'

    it 'sets the scenario input value with the reduced value' do
      # The 6570.0 comes from running CurveHandler::Reducers::FullLoadHours on the curve.
      expect { service.call }
        .to change { scenario.reload.user_values }
        .from({ 'orig' => 1.0 })
        .to({ 'i1' => 6570.0, 'i2' => 6570.0, 'orig' => 1.0 })
    end

    context 'when providing false to the call' do
      it 'will not set the scenario input value with the reduced value' do
        expect { service.call(false) }
          .not_to change { scenario.reload.user_values }
      end
    end
  end
end
