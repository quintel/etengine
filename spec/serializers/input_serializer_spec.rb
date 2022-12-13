# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InputSerializer do
  let(:scenario) { Scenario.default }
  let(:json) { described_class.new(input, scenario, extra_attributes: false).as_json }

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

  context 'when the scenario has a parent' do
    let(:parent) do
      Scenario.new(user_values: { future_input: 5.0 })
    end

    let(:input) { Input.get(:future_input) }

    before do
      allow(scenario).to receive(:parent).and_return(parent)
    end

    context 'when no default value mode is specified' do
      let(:json) do
        described_class.new(input, scenario).as_json
      end

      it 'uses the parent scenario' do
        expect(json[:default]).to eq(5.0)
      end
    end

    context 'when the default value mode is :parent' do
      let(:json) do
        described_class.new(input, scenario, default_values_from: :parent).as_json
      end

      it 'uses the parent scenario' do
        expect(json[:default]).to eq(5.0)
      end
    end

    context 'when the default value mode is :dataset' do
      let(:json) do
        described_class.new(input, scenario, default_values_from: :dataset).as_json
      end

      it 'uses the dataset default scenario' do
        expect(json[:default]).to eq(50.0)
      end
    end
  end
end
