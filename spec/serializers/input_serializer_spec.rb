# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InputSerializer do
  let(:scenario) { Scenario.default }
  let(:json) { described_class.new(input, scenario, false).as_json }

  context 'when the input disables others' do
    let(:input) { Input.get(:exclusive) }

    it 'contains the disables_inputs' do
      expect(json[:disables_inputs]).to eq(%w[both_input future_input])
    end
  end

  context 'when the input does not disable others' do
    let(:input) { Input.get(:exclusive) }

    it 'does not contain disables_inputs' do
      expect(json.key?(:disabled_inputs)).to be(false)
    end
  end

  context 'when the input is disabled by a mutually-exclusive input' do
    let(:input) { Input.get(:both_input) }

    context 'when the exclusive input has no value' do
      it 'does not have a "disabled" key' do
        expect(json.key?(:disabled)).to be(false)
      end
    end

    context 'when the exclusive input has a value' do
      before do
        scenario.user_values = { exclusive: 1.0 }
      end

      it 'does not disables the input' do
        expect(json[:disabled]).to be(true)
      end
    end
  end
end
