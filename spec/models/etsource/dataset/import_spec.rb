# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Etsource::Dataset::Import, :etsource_fixture do
  describe '#load_emission_data' do
    let(:emissions) { described_class.new('nl').send(:load_emission_data) }

    it 'loads flat emission values keyed by joined CSV columns' do
      expect(emissions[:emissions_data][:energy_fugitive_emissions_non_energetic_co2_2023])
        .to eq(20.0)
    end
  end
end
