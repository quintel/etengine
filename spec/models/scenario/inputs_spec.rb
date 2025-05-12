# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Scenario::Inputs do
  let(:scenario) { create(:scenario) }
  let(:inputs) { described_class.new(scenario) }

  context 'when the scenario has an attached curve' do
    let(:curve) do
      create(:user_curve, key: 'a_curve', scenario: scenario).tap do |uc|
        allow(uc).to receive(:curve_config).and_return(
          CurveHandler::Config.from_etsource(
            key: 'a',
            type: 'generic',
            disables: ['both_input']
          )
        )
        allow(uc).to receive(:loadable_curve?).and_return(true)
      end
    end

    before do
      allow(scenario).to receive(:user_curves).and_return([curve])

      scenario.user_values = {
        both_input: 100,
        present_input: 50,
        future_input: 25
      }
    end

    it 'removes the disabled input from the "present" list' do
      expect(inputs.present).to eq({
        Input.get(:present_input) => 50
      })
    end

    it 'removes the disabled input from the "future" list' do
      expect(inputs.future).to eq({
        Input.get(:future_input) => 25
      })
    end
  end

  context 'when a scenario has no inputs' do
    it 'has no before inputs' do
      expect(inputs.before).to be_empty
    end

    it 'has no present inputs' do
      expect(inputs.present).to be_empty
    end

    it 'has no future inputs' do
      expect(inputs.future).to be_empty
    end
  end

  context 'when a scenario has present and future inputs' do
    before do
      scenario.user_values = {
        both_input: 100,   # both
        present_input: 50, # present
        future_input: 25   # future
      }
    end

    it 'has two present inputs and their values' do
      expect(inputs.present).to eq({
        Input.get(:both_input) => 100,
        Input.get(:present_input) => 50
      })
    end

    it 'has two future inputs and their values' do
      expect(inputs.future).to eq({
        Input.get(:both_input) => 100,
        Input.get(:future_input) => 25
      })
    end
  end

  context 'when a scenario has a mutually-exclusive input' do
    before do
      scenario.user_values = {
        exclusive: 100,         # future, disables both and future
        disabled_by_both: 50,   # both
        disabled_by_future: 25, # future
        input_2: 75             # future, not disabled
      }
    end

    it 'has no present inputs' do
      expect(inputs.present).to be_empty
    end

    it 'has no future inputs' do
      expect(inputs.future).to eq({
        Input.get(:exclusive) => 100,
        Input.get(:input_2) => 75
      })
    end
  end

  context 'when a scenario has an active coupling disabling an input' do
    before do
      scenario.user_values = {
        input_disabled_by_coupling: 100,
        input_with_coupling_group: 50
      }

      scenario.activate_coupling("steel_sector")
    end

    it 'enables the coupling_group input and disables the disabled_by_coupling input' do
      expect(inputs.future).to eq({
        Input.get(:input_with_coupling_group) => 50
      })
    end
  end

  context 'when a scenario has an inactive coupling disabling an input' do
    before do
      scenario.user_values = {
        input_disabled_by_coupling: 100,
        input_with_coupling_group: 50
      }

      scenario.deactivate_coupling("steel_sector")
    end

    it 'disables the coupling_group input and enables the disabled_by_coupling input' do
      expect(inputs.future).to eq({
        Input.get(:input_disabled_by_coupling) => 100
      })
    end
  end
end
