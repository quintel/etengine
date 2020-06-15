require 'spec_helper'

module Gql::Runtime::Functions
  describe Legacy, :etsource_fixture do
    let(:gql) { Scenario.default.gql(prepare: true) }

    let(:result) do |example|
      gql.query_future(example.metadata[:example_group][:description])
    end

    # ROUND
    # -----

    describe 'ROUND(1.25)' do
      it('returns 1') { expect(result).to eq(1) }
    end

    describe 'ROUND(1.25, 0)' do
      it('returns 1') { expect(result).to eq(1) }
    end

    describe 'ROUND(1.25, 1)' do
      it('returns 1') { expect(result).to eq(1.3) }
    end

    describe 'ROUND(1.25, 2)' do
      it('returns 1') { expect(result).to eq(1.25) }
    end

    describe 'ROUND(123456)' do
      it('returns 123456') { expect(result).to eq(123456) }
    end

    describe 'ROUND(123456, -3)' do
      it('returns 123000') { expect(result).to eq(123000) }
    end

    # FLOOR
    # -----

    describe 'FLOOR(1.25)' do
      it('returns 1') { expect(result).to eq(1) }
    end

    describe 'FLOOR(1.25, 0)' do
      it('returns 1') { expect(result).to eq(1) }
    end

    describe 'FLOOR(1.25, 1)' do
      it('returns 1') { expect(result).to eq(1.2) }
    end

    describe 'FLOOR(1.25, 2)' do
      it('returns 1') { expect(result).to eq(1.25) }
    end

    describe 'FLOOR(123456)' do
      it('returns 123456') { expect(result).to eq(123456) }
    end

    describe 'FLOOR(123456, -3)' do
      it('returns 123000') { expect(result).to eq(123000) }
    end

    # CEIL
    # ----

    describe 'CEIL(1.25)' do
      it('returns 1') { expect(result).to eq(2) }
    end

    describe 'CEIL(1.25, 0)' do
      it('returns 1') { expect(result).to eq(2) }
    end

    describe 'CEIL(1.25, 1)' do
      it('returns 1') { expect(result).to eq(1.3) }
    end

    describe 'CEIL(1.25, 2)' do
      it('returns 1') { expect(result).to eq(1.25) }
    end

    describe 'CEIL(123456)' do
      it('returns 123456') { expect(result).to eq(123456) }
    end

    describe 'CEIL(123456, -3)' do
      it('returns 123000') { expect(result).to eq(124000) }
    end

    # FLATTEN
    # -------

    describe 'FLATTEN(1, 2, 3)' do
      it('returns [1, 2, 3]') { expect(result).to eq([1, 2, 3]) }
    end

    describe 'FLATTEN(1, 2, 3, 3)' do
      it('returns [1, 2, 3, 3]') { expect(result).to eq([1, 2, 3, 3]) }
    end

    describe 'FLATTEN(1, 2, nil, 2, nil)' do
      it('returns [1, 2, 2]') { expect(result).to eq([1, 2, 2]) }
    end

    describe 'FLATTEN(1, [2, 3], [4])' do
      it('returns [1, 2, 3, 4]') { expect(result).to eq([1, 2, 3, 4]) }
    end

    describe 'FLATTEN([1, [2]], [5])' do
      it('returns [1, 2, 5]') { expect(result).to eq([1, 2, 5]) }
    end

    describe 'FLATTEN(V(1, [2], nil, [nil], [6]))' do
      it('returns [1, 2, 6]') { expect(result).to eq([1, 2, 6]) }
    end
  end
end
