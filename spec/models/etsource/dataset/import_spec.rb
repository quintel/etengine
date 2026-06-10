# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Etsource::Dataset::Import, :etsource_fixture do
  describe '#load_emission_data' do
    let(:emissions) { described_class.new('nl').send(:load_emission_data) }

    it 'loads flat emission values keyed by joined CSV columns' do
      expect(emissions[:emissions_data][:energy_fugitive_emissions_non_energetic_co2_2023])
        .to eq(20.0)
    end

    it 'indexes sectors to their subsector keys' do
      expect(emissions[:emissions_index][:sectors][:energy]).to contain_exactly(
        :energy_electricity_and_heat_production, :energy_fugitive_emissions
      )
    end

    it 'indexes subsector keys' do
      expect(emissions[:emissions_index][:subsectors])
        .to include(:energy_electricity_and_heat_production, :buildings_non_specified)
    end

    it 'indexes scopes including the use' do
      expect(emissions[:emissions_index][:scopes]).to include(
        :energy_fugitive_emissions_non_energetic,
        :agriculture_non_specified_energetic,
        :agriculture_non_specified_non_energetic
      )
    end

    it 'indexes the GHG types' do
      expect(emissions[:emissions_index][:ghgs]).to eq(co2: true, other_ghg: true)
    end
  end
end
