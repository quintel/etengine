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

  describe 'UPDATE(V(no), demand, 10)' do
    before { result }

    it 'does not raise an error' do
      expect { result }.not_to raise_error
    end
  end

  describe 'UPDATE(V(no, nope, also_no), demand, 10)' do
    before { result }

    it 'does not raise an error' do
      expect { result }.not_to raise_error
    end
  end

  describe 'UPDATE(EMISSIONS(households, energetic), other_ghg, 10)' do
    before { result }

    it 'does not raise an error' do
      expect { result }.not_to raise_error
    end

    it 'sets the emissions to 10' do
      expect(gql.query_future('EMISSIONS(households, energetic, other_ghg)')).to eq(10)
    end
  end

  describe 'UPDATE(EMISSIONS(households, energetic), co2, 500.0)' do
    before { result }

    it 'sets the co2 emissions to 500.0' do
      expect(gql.query_future('EMISSIONS(households, energetic, co2)')).to eq(500.0)
    end

    it 'does not affect other_ghg emissions' do
      original = gql.query_future('EMISSIONS(households, energetic, other_ghg)')
      result
      expect(gql.query_future('EMISSIONS(households, energetic, other_ghg)')).to eq(original)
    end
  end

  describe "UPDATE(EMISSIONS('energy.electricity_and_heat_production', energetic), co2, 99.0)" do
    before { result }

    it 'sets the emissions for nested sector' do
      expect(gql.query_future("EMISSIONS('energy.electricity_and_heat_production', energetic, co2)")).to eq(99.0)
    end
  end

  describe 'UPDATE(EMISSIONS(industry, energetic), co2_1990, 1000.0)' do
    before { result }

    it 'sets historical emissions data' do
      expect(gql.query_future('EMISSIONS(industry, energetic, co2, 1990)')).to eq(1000.0)
    end

    it 'does not affect start_year emissions' do
      # Assumes industry co2 start_year was nil or has different value
      result
      start_year_value = gql.query_future('EMISSIONS(industry, energetic, co2)')
      expect(start_year_value).not_to eq(1000.0) unless start_year_value.nil?
    end
  end

  describe 'UPDATE(EMISSIONS(agriculture, energetic), co2, 0.0)' do
    before { result }

    it 'sets emissions to zero' do
      expect(gql.query_future('EMISSIONS(agriculture, energetic, co2)')).to eq(0.0)
    end
  end

  describe 'UPDATE(EMISSIONS(households, energetic), co2, nil)' do
    before { result }

    it 'sets emissions to nil' do
      expect(gql.query_future('EMISSIONS(households, energetic, co2)')).to be_nil
    end
  end
end
