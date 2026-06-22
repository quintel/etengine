require 'spec_helper'
require_relative '../../../lib/graph_data_validation/lib/datasets'

RSpec.describe GraphDataValidation::Datasets, :etsource_fixture do
  context 'with existing area codes' do
    let(:datasets) { described_class.new(:nl, env: :test)}

    it 'initialises gql for each dataset when accessed' do
      expect(datasets.first).to be_a(Gql::Gql)
    end
  end

  context 'with a non existing area code' do
    let(:datasets) { described_class.new(:fantasia_land, env: :test)}

    it 'is empty' do
      expect(datasets.first).to be_nil
    end
  end
end
