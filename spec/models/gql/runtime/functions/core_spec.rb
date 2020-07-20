# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/RepeatedExampleGroupBody
describe Gql::Runtime::Functions::Core, :etsource_fixture do
  let(:gql) { Scenario.default.gql(prepare: true) }
  let(:graph) { gql.future.graph }
  let(:molecule_graph) { gql.future.molecules }

  let(:result) do |example|
    gql.query_future(example.metadata[:example_group][:description])
  end

  # V
  # -

  describe 'V(bar)' do
    it('returns [Node(bar)]') { expect(result).to eq([graph.node(:bar)]) }
  end

  describe 'V(bar, baz)' do
    it('returns [Node(bar), Node(baz)]') do
      expect(result).to eq([
        graph.node(:bar),
        graph.node(:baz)
      ])
    end
  end

  describe 'V(bar, demand)' do
    it('returns 60') { expect(result).to eq(60) }
  end

  describe 'V(bar, baz, demand)' do
    it('returns [60, 50]') { expect(result).to eq([60, 40]) }
  end

  # MV
  # --

  describe 'MV(bar)' do
    it('returns []') { expect(result).to eq([]) }
  end

  describe 'MV(m_left)' do
    it('returns [Node(m_left)]') { expect(result).to eq([molecule_graph.node(:m_left)]) }
  end

  describe 'MV(m_left, demand)' do
    it('returns 100.0') { expect(result).to eq(100) }
  end

  # L
  # -

  describe 'L(bar)' do
    it('returns [Node(bar)]') { expect(result).to eq([graph.node(:bar)]) }
  end

  describe 'L(bar, baz)' do
    it('returns [Node(bar), Node(baz)]') do
      expect(result).to eq([
        graph.node(:bar),
        graph.node(:baz)
      ])
    end
  end

  describe 'L(bar, demand)' do
    it('returns [Node(bar)]') { expect(result).to eq([graph.node(:bar)]) }
  end

  describe 'L(bar, baz, demand)' do
    it('returns [Node(bar), Node(baz)]') do
      expect(result).to eq([graph.node(:bar), graph.node(:baz)])
    end
  end

  # ML
  # --

  describe 'ML(m_left)' do
    it('returns [Node(m_left)]') { expect(result).to eq([molecule_graph.node(:m_left)]) }
  end

  describe 'ML(m_right_one, m_right_two)' do
    it('returns [Node(m_right_one), Node(m_right_two)]') do
      expect(result).to eq([
        molecule_graph.node(:m_right_one),
        molecule_graph.node(:m_right_two)
      ])
    end
  end

  describe 'ML(m_left, demand)' do
    it('returns [Node(m_left)]') { expect(result).to eq([molecule_graph.node(:m_left)]) }
  end

  describe 'ML(m_right_one, m_right_two, demand)' do
    it('returns [Node(m_right_one), Node(m_right_two)]') do
      expect(result).to eq([molecule_graph.node(:m_right_one), molecule_graph.node(:m_right_two)])
    end
  end
end
# rubocop:enable RSpec/RepeatedExampleGroupBody
