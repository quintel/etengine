# frozen_string_literal: true

require 'spec_helper'

describe Inspect::LazyGql, :etsource_fixture do
  let(:scenario) { FactoryBot.create(:scenario) }

  describe '#method_missing' do
    context 'when the dataset exists' do
      it 'initializes GQL and forwards method calls' do
        lazy_gql = Inspect::LazyGql.new(scenario)

        expect(scenario).to receive(:gql).with(prepare: true).and_call_original
        expect(lazy_gql.present_graph).to be_a(Qernel::Graph)
      end

      it 'only initializes GQL once' do
        lazy_gql = Inspect::LazyGql.new(scenario)

        expect(scenario).to receive(:gql).once.with(prepare: true).and_call_original

        lazy_gql.present_graph
        lazy_gql.future_graph
      end
    end

    context 'when the dataset does not exist' do
      let(:scenario_with_invalid_dataset) do
        # Create scenario normally, then update area_code to bypass validation
        scenario = FactoryBot.create(:scenario)
        scenario.update_column(:area_code, 'de')
        scenario
      end

      it 'raises DatasetNotFoundError' do
        lazy_gql = Inspect::LazyGql.new(scenario_with_invalid_dataset)

        expect do
          lazy_gql.present_graph
        end.to raise_error(Inspect::LazyGql::DatasetNotFoundError, /de/)
      end

      it 'includes scenario ID in error message' do
        lazy_gql = Inspect::LazyGql.new(scenario_with_invalid_dataset)

        expect do
          lazy_gql.present_graph
        end.to raise_error(Inspect::LazyGql::DatasetNotFoundError, /scenario #{scenario_with_invalid_dataset.id}/)
      end
    end

    context 'when Atlas raises a non-dataset error' do
      it 're-raises the original error' do
        lazy_gql = Inspect::LazyGql.new(scenario)

        allow(scenario).to receive(:gql).and_raise(
          Atlas::DocumentNotFoundError.new('Could not find a gquery with the key "test"')
        )

        expect do
          lazy_gql.present_graph
        end.to raise_error(Atlas::DocumentNotFoundError, /gquery/)
      end
    end
  end

  describe '#respond_to_missing?' do
    it 'responds to Gql::Gql public instance methods' do
      lazy_gql = Inspect::LazyGql.new(scenario)

      expect(lazy_gql.respond_to?(:present_graph)).to be true
      expect(lazy_gql.respond_to?(:future_graph)).to be true
      expect(lazy_gql.respond_to?(:query)).to be true
    end

    it 'does not respond to non-GQL methods' do
      lazy_gql = Inspect::LazyGql.new(scenario)

      expect(lazy_gql.respond_to?(:nonexistent_method)).to be false
    end
  end
end
