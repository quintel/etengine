# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::NodeFlowPresenter do
  subject do
    CSV.parse(
      described_class.new(graph).as_csv,
      headers: true
    )
  end

  let(:scenario) { FactoryBot.create(:scenario) }

  context 'with the energy graph' do
    let(:graph) { scenario.gql.future.graph }

    it 'has one row for each energy node' do
      expect(subject.length).to eq(Atlas::EnergyNode.all.length)
    end

    it 'has a row for each energy node' do
      expect(subject.first[0]).to eq(Atlas::EnergyNode.all.map(&:key).min.to_s)
    end
  end

  context 'with the molecule graph' do
    let(:graph) { scenario.gql.future.molecules }

    it 'has one row for each molecule node' do
      expect(subject.length).to eq(Atlas::MoleculeNode.all.length)
    end

    it 'has a row for each molecule node' do
      expect(subject.first[0]).to eq(Atlas::MoleculeNode.all.map(&:key).min.to_s)
    end
  end
end
