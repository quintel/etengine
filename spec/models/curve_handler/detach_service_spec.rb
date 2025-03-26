# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'a successful CurveHandler::DetachService' do
  it 'returns true' do
    expect(service.call(user_curve)).to be(true)
  end

  it 'removes the UserCurve' do
    expect { service.call(user_curve) }
      .to change { scenario.reload.user_curves.count }.from(1).to(0)
  end
end

RSpec.describe CurveHandler::DetachService do
  let(:file) do
    fixture_file_upload('price_curve.csv', 'text/csv')
  end

  let(:scenario) do
    scenario = FactoryBot.create(:scenario, user_values: { 'unaffected' => 1.0 })

    # Skip clamping of values and just set the value.
    allow(scenario).to receive(:update_input_clamped) do |key, value|
      scenario.user_values[key] = value
    end

    scenario
  end

  # Used for the attach step; may differ from `config` to simulate missing config
  let(:attach_config) { config }

  let!(:user_curve) do
    CurveHandler::AttachService
      .new(attach_config, file, scenario)
      .call
      .tap { scenario.reload }
  end

  let(:service) { described_class.new(config) }

  context 'with a curve and no reducer' do
    let(:config) { CurveHandler::Config.new(:generic, :generic) }

    include_examples 'a successful CurveHandler::DetachService'

    it 'does not change the scenario inputs' do
      expect { service.call(user_curve) }
        .not_to(change { scenario.reload.user_values })
    end
  end

  context 'with a reducer that sets two inputs' do
    let(:file) { fixture_file_upload('capacity_curve.csv', 'text/csv') }

    let(:config) do
      CurveHandler::Config.new(
        :generic,
        :capacity_profile,
        :full_load_hours,
        %w[input_one input_two]
      )
    end

    include_examples 'a successful CurveHandler::DetachService'

    it 'removes the reducer inputs but keeps others' do
      expect { service.call(user_curve) }
        .to change { scenario.reload.user_values }
        .from({ 'input_one' => 6570.0, 'input_two' => 6570.0, 'unaffected' => 1.0 })
        .to({ 'unaffected' => 1.0 })
    end
  end

  context 'with one reducer input missing' do
    let(:file) { fixture_file_upload('capacity_curve.csv', 'text/csv') }

    let(:config) do
      CurveHandler::Config.new(
        :generic,
        :capacity_profile,
        :full_load_hours,
        %w[input_one input_two]
      )
    end

    before do
      scenario.reload
      scenario.user_values.delete('input_two')
      scenario.save!(validate: false)
    end

    include_examples 'a successful CurveHandler::DetachService'

    it 'removes only the present reducer input' do
      expect { service.call(user_curve) }
        .to change { scenario.reload.user_values }
        .from({ 'input_one' => 6570.0, 'unaffected' => 1.0 })
        .to({ 'unaffected' => 1.0 })
    end
  end

  context 'without a config (no-op)' do
    let(:attach_config) { CurveHandler::Config.new(:generic, :generic) }
    let(:config) { nil }

    include_examples 'a successful CurveHandler::DetachService'

    it 'does not change the scenario inputs' do
      expect { service.call(user_curve) }
        .not_to(change { scenario.reload.user_values })
    end
  end
end
