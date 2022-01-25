# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InputSerializer do
  let(:scenario) { Scenario.default }
  let(:json) { described_class.new(input, scenario, false).as_json }

  context 'when the input is configured to be disabled by another' do
    let(:input) { Input.get(:disabled_by_future) }

    it 'contains the disabled_by key' do
      expect(json[:disabled_by]).to eq(%w[exclusive])
    end
  end

  context 'when the input is not configured be disabled by another' do
    let(:input) { Input.get(:exclusive) }

    it 'does not contain the disabled_by key' do
      expect(json.key?(:disabled_by)).to be(false)
    end
  end

  context 'when the scenario is protected' do
    let(:input) { Input.get(:exclusive) }
    let(:scenario) { FactoryBot.build(:scenario, protected: true) }

    it 'flags the input as disabled' do
      expect(json[:disabled]).to be(true)
    end
  end

  context 'when the input is disabled by a set mutually-exclusive input' do
    let(:input) { Input.get(:disabled_by_future) }

    context 'when the exclusive input has no value' do
      it 'does not have a "disabled" key' do
        expect(json.key?(:disabled)).to be(false)
      end
    end

    context 'when the exclusive input has a value' do
      before do
        scenario.user_values = { exclusive: 1.0 }
      end

      it 'does not disable the input' do
        expect(json[:disabled]).to be(true)
      end
    end
  end
end
