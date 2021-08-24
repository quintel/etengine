# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::RecursiveFactor::BioEmissions do
  # Create a graph:
  #
  #            <- [CCS Plant #1] <- [Torrefied Biomass]
  # [Terminus] <- [CCS Plant #2] <- [Green Gas]
  #            <- [Normal Plant] <- [Coal]
  #
  # All three suppliers have 50 demand. 100% of torrefied biomass is converted to CO2 and 100% is
  # captured on [CCS Plant 1]. 50% of green gas is converted to CO2, and 50% is captured on
  # [CCS Plant 2]. Coal produces no capturable CO2.
  let(:builder) do
    TestGraphBuilder.new.tap do |builder|
      builder.add(:terminus)

      builder.add(:ccs_plant_1, demand: 50, ccs_capture_rate: 1.0)
      builder.add(:ccs_plant_2, demand: 50, ccs_capture_rate: 0.5)
      builder.add(:normal_plant, demand: 50)

      builder.add(:biomass_prod, groups: [:primary_energy_demand])
      builder.add(:greengas_prod, groups: [:primary_energy_demand])
      builder.add(:coal_prod, groups: [:primary_energy_demand])

      builder.connect(:biomass_prod, :ccs_plant_1, :biomass)
      builder.connect(:greengas_prod, :ccs_plant_2, :greengas)
      builder.connect(:coal_prod, :normal_plant, :coal)

      builder.connect(:ccs_plant_1, :terminus, :electricity)
      builder.connect(:ccs_plant_2, :terminus, :electricity)
      builder.connect(:normal_plant, :terminus, :electricity)

      builder.carrier_attrs(:biomass, potential_co2_conversion_per_mj: 1.0)
      builder.carrier_attrs(:greengas, potential_co2_conversion_per_mj: 0.5)
    end
  end

  let(:graph) { builder.to_qernel }

  let(:ccs_plant_1) { graph.node(:ccs_plant_1) }
  let(:ccs_plant_2) { graph.node(:ccs_plant_2) }
  let(:normal_plant) { graph.node(:normal_plant) }
  let(:terminus) { graph.node(:terminus) }

  context 'when the CCS plants have capture' do
    it 'captures 50 on CCS Plant #1' do
      expect(ccs_plant_1).to have_query_value(:captured_bio_emissions, 50)
    end

    it 'captures 12.5 on CCS Plant #2' do
      expect(ccs_plant_2).to have_query_value(:captured_bio_emissions, 12.5)
    end

    it 'captures nothing on Normal Plant' do
      expect(normal_plant).to have_query_value(:captured_bio_emissions, 0)
    end

    it 'captures nothing on Terminus' do
      expect(terminus).to have_query_value(:captured_bio_emissions, 0)
    end

    it 'Terminus inherits 62.5 captures CO2' do
      expect(terminus).to have_query_value(:inherited_captured_bio_emissions, 62.5)
    end
  end

  context 'when CCS plant 1 has no capture' do
    before do
      builder.node(:ccs_plant_1).set(:ccs_capture_rate, 0.0)
    end

    it 'captures nothing on CCS Plant #1' do
      expect(ccs_plant_1).to have_query_value(:captured_bio_emissions, 0)
    end

    it 'Terminus inherits 12.5 captures CO2' do
      expect(terminus).to have_query_value(:inherited_captured_bio_emissions, 12.5)
    end
  end

  context 'when CCS plant 1 has nil capture' do
    before do
      builder.node(:ccs_plant_1).set(:ccs_capture_rate, nil)
    end

    it 'captures nothing on CCS Plant #1' do
      expect(ccs_plant_1).to have_query_value(:captured_bio_emissions, 0)
    end

    it 'Terminus inherits 12.5 captures CO2' do
      expect(terminus).to have_query_value(:inherited_captured_bio_emissions, 12.5)
    end
  end

  context 'when the normal plant has capture' do
    before do
      builder.node(:normal_plant).set(:ccs_capture_rate, 1.0)
    end

    it 'captures nothing on the Normal Plant' do
      expect(normal_plant).to have_query_value(:captured_bio_emissions, 0)
    end

    it 'Terminus inherits 62.5 captures CO2' do
      expect(terminus).to have_query_value(:inherited_captured_bio_emissions, 62.5)
    end
  end

  context 'when CCS plant #1 has outputs electricity=0.5 loss=0.5' do
    before do
      builder.node(:ccs_plant_1).slots.out(:electricity).set(:share, 0.5)
      builder.node(:ccs_plant_1).slots.out.add(:loss, share: 0.5)
    end

    it 'captures 50 on CCS Plant #1' do
      expect(ccs_plant_1).to have_query_value(:captured_bio_emissions, 50)
    end

    it 'Terminus inherits 62.5 captures CO2' do
      expect(terminus).to have_query_value(:inherited_captured_bio_emissions, 62.5)
    end
  end

  context 'when CCS plant #1 has outputs electricity=0.5 gas=0.5' do
    before do
      builder.node(:ccs_plant_1).slots.out(:electricity).set(:share, 0.5)
      builder.node(:ccs_plant_1).slots.out.add(:gas, share: 0.5)
    end

    it 'captures 50 on CCS Plant #1' do
      expect(ccs_plant_1).to have_query_value(:captured_bio_emissions, 50)
    end

    it 'Terminus inherits 37.5 captures CO2' do
      expect(terminus).to have_query_value(:inherited_captured_bio_emissions, 37.5)
    end
  end

  context 'when CCS plant #1 has outputs electricity=0.6 gas=0.6' do
    before do
      builder.node(:ccs_plant_1).slots.out(:electricity).set(:share, 0.6)
      builder.node(:ccs_plant_1).slots.out.add(:gas, share: 0.6)
    end

    it 'captures 50 on CCS Plant #1' do
      expect(ccs_plant_1).to have_query_value(:captured_bio_emissions, 50)
    end

    it 'Terminus inherits 37.5 captures CO2' do
      expect(terminus).to have_query_value(:inherited_captured_bio_emissions, 37.5)
    end
  end

  context 'when the CCS plants have capture and fossil emissions' do
    before do
      builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.5)
      builder.node(:ccs_plant_1).set(:ccs_capture_rate, 0.0)
      builder.node(:ccs_plant_2).set(:ccs_capture_rate, 0.0)
    end

    it 'has 25 emissions on Terminus' do
      # Comes from the "normal" plant.
      expect(terminus).to have_query_value(:primary_co2_emission, 25.0)
    end

    it 'captures nothing on Terminus' do
      expect(terminus).to have_query_value(:inherited_captured_bio_emissions, 0.0)
    end

    it 'has 100 CO2 and bio CO2 on Terminus' do
      # 25 primary CO2 from the "normal" plant, and 75 via the two CCS plants.
      expect(terminus).to have_query_value(:primary_co2_emission_of_bio_and_fossil, 100.0)
    end
  end
end
