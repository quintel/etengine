# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Scenario::Projector do
  let(:from) do
    FactoryBot.create(:scenario, {
      user_values: { input_1: 1, input_2: 0}
    })
  end

  let(:onto) do
    FactoryBot.create(:scenario, {
      user_values: { input_1: 0,input_2: 1, input_3: 1 }
    })
  end

  subject { described_class.new(from, onto, ['input_1']) }

  it { is_expected.to respond_to :call }
  it { is_expected.to respond_to :as_json }

  describe '#call' do
    subject { described_class.new(from, onto, ['input_1']).call }

    it 'create a scenario' do
      from
      onto
      expect { subject }.to change { Scenario.count }.by(1)
    end

    it 'returns a scenario' do
      expect(subject).to be_a Scenario
    end

    describe 'user_values'
      context 'with provided sliders' do
        context 'that occurs in "from"' do
          it 'have the same value as "from"' do
            expect(subject.user_values[:input_1])
              .to eq from.user_values[:input_1]
          end
        end

        context 'that dont occur in "from"' do
          it 'have the same value as "onto"' do
            expect(subject.user_values[:input_3])
              .to eq onto.user_values[:input_3]
          end
        end
      end

      context 'with an ommited slider' do
        it 'have the value of "onto"' do
          expect(subject.user_values[:input_2]).to eq onto.user_values[:input_2]
        end
      end
  end
end
