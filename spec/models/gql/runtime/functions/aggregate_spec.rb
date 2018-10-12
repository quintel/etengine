require 'spec_helper'

module Gql::Runtime::Functions
  describe Aggregate, :etsource_fixture do
    let(:gql) { Scenario.default.gql(prepare: true) }

    let(:result) do |example|
      gql.query_future(example.metadata[:example_group][:description])
    end

    # DIVIDE
    # ------

    describe 'DIVIDE(nil, nil)' do
      it('returns 0.0') { expect(result).to eq(0.0) }
    end

    describe 'DIVIDE(nil, 0)' do
      it('returns 0.0') { expect(result).to eq(0.0) }
    end

    describe 'DIVIDE(0, 0)' do
      it('returns 0.0') { expect(result).to eq(0.0) }
    end

    describe 'DIVIDE(1, 0)' do
      it('returns 0.0') { expect(result).to eq(0.0) }
    end

    describe 'DIVIDE(0, 1)' do
      it('returns 0.0') { expect(result).to eq(0.0) }
    end

    describe 'DIVIDE(1, 2)' do
      it('returns 0.5') { expect(result).to eq(0.5) }
    end

    describe 'DIVIDE([1, 2])' do
      it('returns 0.5') { expect(result).to eq(0.5) }
    end
  end
end
