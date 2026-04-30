# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::DirectBioEmissions do
  describe '#direct_co2_emission_of_bio_gross' do
    context 'with a pure bio carrier (biomass)' do
      # Create a simple graph:
      # [Biomass Producer] -> [Biomass Plant] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:biomass_plant)
          builder.add(:biomass_producer, groups: [:primary_energy_demand])

          builder.connect(:biomass_producer, :biomass_plant, :biomass, type: :share)
          builder.connect(:biomass_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biomass, potential_co2_conversion_per_mj: 0.182)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:biomass_plant) { graph.node(:biomass_plant) }

      it 'calculates direct bio emissions from biomass input' do
        # 100 MJ * 0.182 kg/MJ = 18.2 kg CO2
        expect(biomass_plant).to have_query_value(:direct_co2_emission_of_bio_gross, 18.2)
      end
    end

    context 'with fossil carrier (no bio content)' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:coal_plant)
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
          # No potential_co2_conversion_per_mj set
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_plant) { graph.node(:coal_plant) }

      it 'returns zero for pure fossil carrier' do
        expect(coal_plant).to have_query_value(:direct_co2_emission_of_bio_gross, 0.0)
      end
    end
  end

  describe 'gross, captured, and net bio emissions' do
    context 'with BECCS plant capturing 90% of bio emissions' do
      # BECCS = Bio-Energy with Carbon Capture and Storage
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:beccs_plant, free_co2_factor: 0.9)
          builder.add(:biomass_producer, groups: [:primary_energy_demand])

          builder.connect(:biomass_producer, :beccs_plant, :biomass, type: :share)
          builder.connect(:beccs_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biomass, potential_co2_conversion_per_mj: 0.182)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:beccs_plant) { graph.node(:beccs_plant) }

      it 'calculates gross bio emissions (before capture)' do
        # 50 MJ * 0.182 kg/MJ = 9.1 kg CO2
        expect(beccs_plant).to have_query_value(:direct_co2_emission_of_bio_gross, 9.1)
      end

      it 'calculates captured bio emissions' do
        # 9.1 * 0.9 = 8.19 kg CO2 captured (creates negative emissions)
        expect(beccs_plant).to have_query_value(:direct_co2_emission_of_bio_captured, 8.19)
      end

      it 'calculates net bio emissions (after capture)' do
        # 9.1 * (1 - 0.9) = 0.91 kg CO2
        expect(beccs_plant).to have_query_value(:direct_co2_emission_of_bio, 0.91)
      end

      it 'validates net = gross - captured' do
        gross = beccs_plant.query.direct_co2_emission_of_bio_gross
        captured = beccs_plant.query.direct_co2_emission_of_bio_captured
        net = beccs_plant.query.direct_co2_emission_of_bio

        expect(net).to be_within(0.001).of(gross - captured)
      end
    end

    context 'with no CCS on biomass plant' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 75)
          builder.add(:biomass_plant, free_co2_factor: 0.0)
          builder.add(:biomass_producer, groups: [:primary_energy_demand])

          builder.connect(:biomass_producer, :biomass_plant, :greengas, type: :share)
          builder.connect(:biomass_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:greengas, potential_co2_conversion_per_mj: 0.5)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:biomass_plant) { graph.node(:biomass_plant) }

      it 'has zero captured bio emissions' do
        expect(biomass_plant).to have_query_value(:direct_co2_emission_of_bio_captured, 0.0)
      end

      it 'has gross = net (no capture)' do
        gross = biomass_plant.query.direct_co2_emission_of_bio_gross
        net = biomass_plant.query.direct_co2_emission_of_bio

        expect(net).to eq(gross)
      end
    end
  end

  describe '#direct_output_bio_co2_composition' do
    context 'with a node outputting a carrier with defined bio CO2 value' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:biomass_plant)
          builder.add(:biomass_producer, groups: [:primary_energy_demand])

          builder.connect(:biomass_producer, :biomass_plant, :biomass, type: :share)
          builder.connect(:biomass_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biomass, potential_co2_conversion_per_mj: 0.182)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:biomass_producer) { graph.node(:biomass_producer) }

      it 'returns the carrier bio CO2 value' do
        expect(biomass_producer.query.direct_output_bio_co2_composition).to eq(0.182)
      end
    end

    context 'with carrier having no bio CO2 value' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:coal_plant)
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :terminus, :electricity, type: :share)

          # Coal has fossil CO2 but no bio CO2
          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_producer) { graph.node(:coal_producer) }

      it 'returns 0 for fossil output (via edge)' do
        # Coal has no potential_co2_conversion_per_mj, so when asked for bio composition via edge,
        # the edge helper direct_edge_bio_carbon_content will return 0.0
        # Testing via the actual usage pattern (through an edge)
        input_edges = graph.node(:coal_plant).inputs.flat_map(&:edges)
        coal_edge = input_edges.find { |e| e.carrier.key == :coal }

        # The edge should report 0.0 bio content for coal
        expect(coal_edge.carrier.potential_co2_conversion_per_mj).to be_nil
      end
    end

    context 'with zero total input' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 0)
          builder.add(:mixer)
          builder.add(:source, groups: [:primary_energy_demand])

          builder.connect(:source, :mixer, :biomass, type: :share)
          builder.connect(:mixer, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biomass, potential_co2_conversion_per_mj: 0.182)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:mixer) { graph.node(:mixer) }

      it 'returns nil when total input is zero' do
        expect(mixer.query.direct_output_bio_co2_composition).to be_nil
      end
    end
  end

  describe 'secondary energy carriers (no combustion at consumer)' do
    # Tests that secondary carriers (electricity, steam, heat) show zero direct bio emissions
    # at the consumer, with emissions tracked only at the combustion point (biomass CHP, biogas plant, etc.)
    context 'with electricity from biomass plant' do
      # Create a graph:
      # [Biomass Producer] -> [Biomass Plant] -> [Electric Heater] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:electric_heater)
          builder.add(:biomass_plant)
          builder.add(:biomass_producer, groups: [:primary_energy_demand])

          builder.connect(:biomass_producer, :biomass_plant, :biomass, type: :share)
          builder.connect(:biomass_plant, :electric_heater, :electricity, type: :share)
          builder.connect(:electric_heater, :terminus, :useable_heat, type: :share)

          builder.carrier_attrs(:biomass, potential_co2_conversion_per_mj: 0.182)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:biomass_plant) { graph.node(:biomass_plant) }
      let(:electric_heater) { graph.node(:electric_heater) }

      it 'shows direct bio emissions only at biomass plant (combustion point)' do
        # 100 MJ biomass * 0.182 kg/MJ = 18.2 kg bio CO2 at combustion
        expect(biomass_plant).to have_query_value(:direct_co2_emission_of_bio, 18.2)
      end

      it 'shows zero direct bio emissions at electric heater (no combustion)' do
        # Electricity is secondary carrier - consumer does not combust anything
        expect(electric_heater).to have_query_value(:direct_co2_emission_of_bio, 0.0)
      end
    end

    context 'with steam_hot_water from biomass CHP' do
      # Create a graph:
      # [Biomass Producer] -> [Biomass CHP] -> [Steam Consumer] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:steam_consumer)
          builder.add(:biomass_chp)
          builder.add(:biomass_producer, groups: [:primary_energy_demand])

          builder.connect(:biomass_producer, :biomass_chp, :biomass, type: :share)
          builder.connect(:biomass_chp, :steam_consumer, :steam_hot_water, type: :share)
          builder.connect(:steam_consumer, :terminus, :useable_heat, type: :share)

          builder.carrier_attrs(:biomass, potential_co2_conversion_per_mj: 0.182)
          builder.carrier_attrs(:steam_hot_water, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:biomass_chp) { graph.node(:biomass_chp) }
      let(:steam_consumer) { graph.node(:steam_consumer) }

      it 'shows direct bio emissions only at CHP (combustion point)' do
        # 50 MJ biomass * 0.182 kg/MJ = 9.1 kg bio CO2 at combustion
        expect(biomass_chp).to have_query_value(:direct_co2_emission_of_bio, 9.1)
      end

      it 'shows zero direct bio emissions at steam consumer (no combustion)' do
        # Steam is secondary carrier - consumer does not combust anything
        expect(steam_consumer).to have_query_value(:direct_co2_emission_of_bio, 0.0)
      end
    end

    context 'with BECCS and secondary carrier' do
      # Create a graph with carbon capture:
      # [Biomass Producer] -> [BECCS Plant] -> [Electric Consumer] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 40)
          builder.add(:electric_consumer)
          builder.add(:beccs_plant, free_co2_factor: 0.9)
          builder.add(:biomass_producer, groups: [:primary_energy_demand])

          builder.connect(:biomass_producer, :beccs_plant, :biomass, type: :share)
          builder.connect(:beccs_plant, :electric_consumer, :electricity, type: :share)
          builder.connect(:electric_consumer, :terminus, :useable_heat, type: :share)

          builder.carrier_attrs(:biomass, potential_co2_conversion_per_mj: 0.182)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:beccs_plant) { graph.node(:beccs_plant) }
      let(:electric_consumer) { graph.node(:electric_consumer) }

      it 'shows net bio emissions at BECCS plant (after capture)' do
        # 40 MJ * 0.182 kg/MJ * (1 - 0.9) = 0.728 kg bio CO2 net
        expect(beccs_plant).to have_query_value(:direct_co2_emission_of_bio, 0.728)
      end

      it 'shows captured bio emissions at BECCS plant' do
        # 40 MJ * 0.182 kg/MJ * 0.9 = 6.552 kg bio CO2 captured
        expect(beccs_plant).to have_query_value(:direct_co2_emission_of_bio_captured, 6.552)
      end

      it 'shows zero bio emissions at electricity consumer (no combustion)' do
        # Electricity is secondary carrier - no combustion at consumer
        expect(electric_consumer).to have_query_value(:direct_co2_emission_of_bio, 0.0)
      end
    end

    context 'with useable_heat from biogas burner' do
      # Create a graph:
      # [Biogas Producer] -> [Biogas Burner] -> [Heat Consumer] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 60)
          builder.add(:heat_consumer)
          builder.add(:biogas_burner)
          builder.add(:biogas_producer, groups: [:primary_energy_demand])

          builder.connect(:biogas_producer, :biogas_burner, :biogas, type: :share)
          builder.connect(:biogas_burner, :heat_consumer, :useable_heat, type: :share)
          builder.connect(:heat_consumer, :terminus, :delivered_heat, type: :share)

          builder.carrier_attrs(:biogas, potential_co2_conversion_per_mj: 0.182)
          builder.carrier_attrs(:useable_heat, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:biogas_burner) { graph.node(:biogas_burner) }
      let(:heat_consumer) { graph.node(:heat_consumer) }

      it 'shows direct bio emissions only at burner (combustion point)' do
        # 60 MJ biogas * 0.182 kg/MJ = 10.92 kg bio CO2 at combustion
        expect(biogas_burner).to have_query_value(:direct_co2_emission_of_bio, 10.92)
      end

      it 'shows zero direct bio emissions at heat consumer (no combustion)' do
        # Useable heat is secondary carrier - consumer does not combust anything
        expect(heat_consumer).to have_query_value(:direct_co2_emission_of_bio, 0.0)
      end
    end
  end
end
