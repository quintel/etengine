# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Scenario::Inputs do
  let(:scenario) { Scenario.new }
  let(:inputs) { described_class.new(scenario) }

  context 'when the scenario is not read-only' do
    let(:scenario) { FactoryBot.build(:scenario, api_read_only: false) }

    it 'does not mark inputs as disabled' do
      expect(inputs.disabled?(Input.get(:exclusive))).to be(false)
    end
  end

  context 'when the scenario is read-only' do
    let(:scenario) { FactoryBot.build(:scenario, api_read_only: true) }

    it 'marks inputs as disabled' do
      expect(inputs.disabled?(Input.get(:exclusive))).to be(true)
    end
  end

  context 'when the scenario has an attached curve' do
    before do
      attachment = scenario.attachments.build(key: 'a_curve')
      allow(attachment).to receive(:loadable_curve?).and_return(true)

      allow(attachment).to receive(:curve_config).and_return(
        CurveHandler::Config.from_etsource({
          key: 'a',
          type: 'generic',
          disables: ['both_input']
        })
      )

      scenario.user_values = {
        both_input: 100,
        present_input: 50,
        future_input: 25
      }
    end

    it 'has removes the disabled input from the "present" list' do
      expect(inputs.present).to eq({
        Input.get(:present_input) => 50
      })
    end

    it 'has removes the disabled input from the "future" list' do
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
end
