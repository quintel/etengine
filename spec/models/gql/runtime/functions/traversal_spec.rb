# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/RepeatedExampleGroupBody
describe Gql::Runtime::Functions::Lookup, :etsource_fixture do
  let(:gql) { Scenario.default.gql(prepare: true) }

  let(:result) do |example|
    gql.query_future(example.metadata[:example_group][:description])
  end

  # EDGE
  # ----

  describe 'EDGE(no, also_no)' do
    it 'returns nil' do
      expect(result).to be_nil
    end
  end

  describe 'EDGE(foo, no)' do
    it 'returns nil' do
      expect(result).to be_nil
    end
  end

  describe 'EDGE(no, foo)' do
    it 'returns nil' do
      expect(result).to be_nil
    end
  end

  describe 'EDGE(foo, bar)' do
    it 'returns an edge' do
      expect(result).to be_kind_of(Qernel::Edge)
    end

    it 'returns an edge which connects to :foo' do
      expect(result.lft_node.key).to eq(:foo)
    end

    it 'returns an edge which connects to :bar' do
      expect(result.rgt_node.key).to eq(:bar)
    end
  end

  describe 'EDGE(bar, foo)' do
    it 'returns an edge' do
      expect(result).to be_kind_of(Qernel::Edge)
    end

    it 'returns an edge which connects to :foo' do
      expect(result.lft_node.key).to eq(:foo)
    end

    it 'returns an edge which connects to :bar' do
      expect(result.rgt_node.key).to eq(:bar)
    end
  end

  # MEDGE
  # -----

  describe 'MEDGE(no, also_no)' do
    it 'returns nil' do
      expect(result).to be_nil
    end
  end

  describe 'MEDGE(m_left, no)' do
    it 'returns nil' do
      expect(result).to be_nil
    end
  end

  describe 'MEDGE(no, m_left)' do
    it 'returns nil' do
      expect(result).to be_nil
    end
  end

  describe 'MEDGE(m_right_one, m_left)' do
    it 'returns an edge' do
      expect(result).to be_kind_of(Qernel::Edge)
    end

    it 'returns an edge which connects to :m_left' do
      expect(result.lft_node.key).to eq(:m_left)
    end

    it 'returns an edge which connects to :bar' do
      expect(result.rgt_node.key).to eq(:m_right_one)
    end
  end

  describe 'MEDGE(m_left, m_right_one)' do
    it 'returns an edge' do
      expect(result).to be_kind_of(Qernel::Edge)
    end

    it 'returns an edge which connects to :m_left' do
      expect(result.lft_node.key).to eq(:m_left)
    end

    it 'returns an edge which connects to :bar' do
      expect(result.rgt_node.key).to eq(:m_right_one)
    end
  end
end
# rubocop:enable RSpec/RepeatedExampleGroupBody
