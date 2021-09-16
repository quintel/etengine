# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/RepeatedExampleGroupBody
describe Gql::Runtime::Functions::Update, :etsource_fixture do
  let(:gql) { Scenario.default.gql(prepare: true) }
  let(:graph) { gql.future.graph }

  let(:result) do |example|
    gql.query_future(example.metadata[:example_group][:description])
  end

  # UPDATE
  # ----

  describe 'UPDATE(V(bar), demand, 10)' do
    before { result }

    it 'sets the node demand to 10' do
      expect(graph.node(:bar).demand).to eq(10)
    end
  end

  describe 'UPDATE(V(bar, baz), demand, 10)' do
    before { result }

    it 'sets the "bar" node demand to 10' do
      expect(graph.node(:bar).demand).to eq(10)
    end

    it 'sets the "baz" node demand to 10' do
      expect(graph.node(:baz).demand).to eq(10)
    end
  end

  describe 'UPDATE(V(no, nope, also_no), demand, 10)' do
    before { result }

    it 'does not raise an error' do
      expect { result }.not_to raise_error
    end
  end
end
