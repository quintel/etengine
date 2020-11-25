# frozen_string_literal: true

require 'spec_helper'

module Gql::Runtime::Functions
  describe Curves, :etsource_fixture do
    let(:gql) { Scenario.default.gql(prepare: true) }

    let(:result) do |example|
      gql.query_future(example.metadata[:example_group][:description])
    end

    # CUMULATIVE_CURVE
    # ----------------

    describe 'CUMULATIVE_CURVE([])' do
      it('returns []') { expect(result).to eq([]) }
    end

    describe 'CUMULATIVE_CURVE([1, 2, 3])' do
      it('returns [1, 3, 6]') { expect(result).to eq([1, 3, 6]) }
    end

    describe 'CUMULATIVE_CURVE([1, 2, -3, 4, -5])' do
      it('returns [1, 3, 0, 4, -1]') { expect(result).to eq([1, 3, 0, 4, -1]) }
    end
  end
end
