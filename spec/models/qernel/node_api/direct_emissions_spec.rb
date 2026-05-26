# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::DirectEmissions do
  describe '#direct_co2_input_content_carriers_fossil' do
    context 'with a pure fossil carrier (coal)' do
      # Create a simple graph:
      # [Coal Producer] -> [Power Plant] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:power_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :power_plant, :coal, type: :share)
          builder.connect(:power_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:power_plant) { graph.node(:power_plant) }

      it 'calculates direct emissions from coal input' do
        # 100 MJ * 0.09 kg/MJ = 9 kg CO2
        expect(power_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 9.0)
      end
    end

    context 'with a pure fossil carrier (natural gas)' do
      # Create a simple graph:
      # [Gas Producer] -> [Gas Plant] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 200)
          builder.add(:gas_plant, groups: [:emissions])
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :gas_plant, :natural_gas, type: :share)
          builder.connect(:gas_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:gas_plant) { graph.node(:gas_plant) }

      it 'calculates direct emissions from natural gas input' do
        # 200 MJ * 0.0564 kg/MJ = 11.28 kg CO2
        expect(gas_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 11.28)
      end
    end

    context 'with secondary carriers (electricity)' do
      # Create a graph:
      # [Coal Producer] -> [Power Plant] -> [Electric Heater] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:electric_heater, groups: [:emissions])
          builder.add(:power_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :power_plant, :coal, type: :share)
          builder.connect(:power_plant, :electric_heater, :electricity, type: :share)
          builder.connect(:electric_heater, :terminus, :heat, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:electric_heater) { graph.node(:electric_heater) }
      let(:power_plant) { graph.node(:power_plant) }

      it 'returns zero for electricity consumer (no direct emissions)' do
        # Electricity has no carbon content
        expect(electric_heater).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end

      it 'shows emissions at the power plant' do
        # 50 MJ * 0.09 kg/MJ = 4.5 kg CO2
        expect(power_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 4.5)
      end
    end

    pending 'with CCS capture (free_co2_factor)' do
      # Create a graph:
      # [Gas Producer] -> [CCS Plant] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:ccs_plant, groups: [:emissions], free_co2_factor: 0.85)
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :ccs_plant, :natural_gas, type: :share)
          builder.connect(:ccs_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:ccs_plant) { graph.node(:ccs_plant) }

      it 'reduces emissions by capture rate' do
        # 100 MJ * 0.0564 kg/MJ * (1 - 0.85) = 0.846 kg CO2
        expect(ccs_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.846)
      end
    end

    context 'with multi-level supply chain' do
      # Create a graph:
      # [Coal Producer] -> [Coal Plant] -> [Electricity Grid] -> [Data Center] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:data_center, groups: [:emissions])
          builder.add(:electricity_grid, groups: [:emissions])
          builder.add(:coal_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :electricity_grid, :electricity, type: :share)
          builder.connect(:electricity_grid, :data_center, :electricity, type: :share)
          builder.connect(:data_center, :terminus, :computing, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_plant) { graph.node(:coal_plant) }
      let(:electricity_grid) { graph.node(:electricity_grid) }
      let(:data_center) { graph.node(:data_center) }

      it 'shows emissions only at coal plant' do
        # 50 MJ * 0.09 kg/MJ = 4.5 kg CO2
        expect(coal_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 4.5)
      end

      it 'shows zero emissions at electricity grid' do
        # Electricity has no carbon content
        expect(electricity_grid).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end

      it 'shows zero emissions at data center' do
        # Electricity has no carbon content
        expect(data_center).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end
    end

    context 'with crude oil' do
      # Create a graph:
      # [Oil Extraction] -> [Refinery] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:refinery, groups: [:emissions])
          builder.add(:oil_extraction, groups: [:primary_energy_demand])

          builder.connect(:oil_extraction, :refinery, :crude_oil, type: :share)
          builder.connect(:refinery, :terminus, :diesel, type: :share)

          builder.carrier_attrs(:crude_oil, co2_conversion_per_mj: 0.0733)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:refinery) { graph.node(:refinery) }

      it 'uses carrier CO2 value' do
        # 100 MJ * 0.0733 kg/MJ = 7.33 kg CO2
        expect(refinery).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.33)
      end
    end

    context 'with crude oil mix (skip carrier value)' do
      # Create a graph that blends different oil sources:
      # [Conventional Oil (70 MJ)] -> [Oil Blender] -> [Refinery] -> [Terminus]
      # [Heavy Oil (30 MJ)]        ->       ^
      #
      # Edge from blender to refinery is marked to skip crude_oil carrier value
      # and calculate composition from the supply mix instead
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:refinery, groups: [:emissions])
          builder.add(:oil_blender, groups: [:emissions])
          builder.add(:conventional_oil, groups: [:primary_energy_demand], demand: 70)
          builder.add(:heavy_oil, groups: [:primary_energy_demand], demand: 30)

          # Oil sources with different CO2 content
          builder.connect(:conventional_oil, :oil_blender, :crude_oil, type: :share)
          builder.connect(:heavy_oil, :oil_blender, :crude_oil_heavy, type: :share)

          # Edge marked to skip carrier value and calculate from mix
          builder.connect(:oil_blender, :refinery, :crude_oil, type: :share, groups: [:emissions_skip_crude_oil_mix])
          builder.connect(:refinery, :terminus, :diesel, type: :share)

          # Conventional crude oil: 0.0733 kg CO2/MJ
          builder.carrier_attrs(:crude_oil, co2_conversion_per_mj: 0.0733)
          # Heavy crude oil: 0.0850 kg CO2/MJ (higher emissions)
          builder.carrier_attrs(:crude_oil_heavy, co2_conversion_per_mj: 0.0850)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:refinery) { graph.node(:refinery) }
      let(:oil_blender) { graph.node(:oil_blender) }

      it 'calculates refinery input from supply mix, not carrier value' do
        # Expected: weighted average based on supply mix
        # (70 * 0.0733 + 30 * 0.0850) / 100 = 0.07681 kg CO2/MJ
        # 100 MJ * 0.07681 kg/MJ = 7.681 kg CO2
        expect(refinery).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.681)
      end

      it 'calculates blender input content from mixed sources' do
        # Blender receives:
        # - 70 MJ conventional crude @ 0.0733 kg/MJ = 5.131 kg
        # - 30 MJ heavy crude @ 0.0850 kg/MJ = 2.55 kg
        # Total input: 7.681 kg CO2
        expect(oil_blender).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.681)
      end

      it 'calculates blender output content using weighted composition' do
        # Blender outputs 100 MJ crude_oil with skip group
        # Should use weighted composition (0.07681 kg/MJ), not carrier value (0.0733 kg/MJ)
        # 100 MJ * 0.07681 kg/MJ = 7.681 kg CO2
        expect(oil_blender).to have_query_value(:direct_co2_output_content_carriers_fossil, 7.681)
      end

      it 'preserves mass balance at blender (pass-through node)' do
        # For a pass-through blender: A (input) - C (output) = E (emissions)
        # Since no combustion occurs: E should be 0
        # Therefore: A should equal C
        input = oil_blender.query.direct_co2_input_content_carriers_fossil
        output = oil_blender.query.direct_co2_output_content_carriers_fossil
        emissions = oil_blender.query.direct_co2_output_production_emissions_fossil

        expect(input).to be_within(0.0000001).of(output)
        expect(emissions).to be_within(0.0000001).of(0.0)
      end
    end

    context 'with crude oil skip group on linear chain' do
      # Create a linear chain that mimics real ETSource structure:
      # [Crude Oil Producer] -> [Final Demand] -> [Space Heating Demand] -> [Space Heater] -> [Terminus]
      #                                           (skip edge)              (skip edge)
      #
      # This tests that the skip group works correctly through multiple levels
      # and that intermediate nodes behave as pass-through without emissions
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:buildings_space_heater_crude_oil, groups: [:emissions])
          builder.add(:buildings_final_demand_for_space_heating_crude_oil, groups: [:emissions])
          builder.add(:buildings_final_demand_crude_oil, groups: [:emissions])
          builder.add(:crude_oil_producer, groups: [:primary_energy_demand])

          # Connect producer to final demand
          builder.connect(:crude_oil_producer, :buildings_final_demand_crude_oil, :crude_oil, type: :share)

          # Connect final demand to intermediate (with skip group)
          builder.connect(
            :buildings_final_demand_crude_oil,
            :buildings_final_demand_for_space_heating_crude_oil,
            :crude_oil,
            type: :share,
            groups: [:emissions_skip_crude_oil_mix]
          )

          # Connect intermediate to consumer (with skip group)
          builder.connect(
            :buildings_final_demand_for_space_heating_crude_oil,
            :buildings_space_heater_crude_oil,
            :crude_oil,
            type: :share,
            groups: [:emissions_skip_crude_oil_mix]
          )

          # Connect consumer to terminus
          builder.connect(:buildings_space_heater_crude_oil, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:crude_oil, co2_conversion_per_mj: 0.0733)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:source) { graph.node(:buildings_final_demand_crude_oil) }
      let(:intermediate) { graph.node(:buildings_final_demand_for_space_heating_crude_oil) }
      let(:consumer) { graph.node(:buildings_space_heater_crude_oil) }

      it 'preserves mass balance at intermediate node (pass-through)' do
        # Intermediate node should not produce emissions, just pass energy through
        input = intermediate.query.direct_co2_input_content_carriers_fossil
        output = intermediate.query.direct_co2_output_content_carriers_fossil
        emissions = intermediate.query.direct_co2_output_production_emissions_fossil

        expect(input).to be_within(0.0000001).of(output)
        expect(emissions).to be_within(0.0000001).of(0.0)
      end

      it 'calculates input content correctly at intermediate node' do
        # Intermediate receives 100 MJ @ 0.0733 kg/MJ = 7.33 kg CO2
        expect(intermediate).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.33)
      end

      it 'calculates output content correctly at intermediate node' do
        # Pass-through: output should equal input
        expect(intermediate).to have_query_value(:direct_co2_output_content_carriers_fossil, 7.33)
      end

      it 'shows zero production emissions at intermediate node' do
        # No combustion at intermediate node
        expect(intermediate).to have_query_value(:direct_co2_output_production_emissions_fossil, 0.0)
      end

      it 'calculates input content correctly at consumer node' do
        # Consumer receives 100 MJ @ 0.0733 kg/MJ = 7.33 kg CO2
        expect(consumer).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.33)
      end

      it 'shows production emissions at consumer (combustion point)' do
        # Consumer burns 100 MJ crude oil
        # A (input) - C (output) = E (emissions)
        # 7.33 - 0 = 7.33 kg CO2
        expect(consumer).to have_query_value(:direct_co2_output_production_emissions_fossil, 7.33)
      end
    end

    context 'with mixed supply propagating through skip chain' do
      # Create a chain with mixed crude oil sources to test composition propagation:
      # [Conventional Oil 70%] -> [Blender] -> [Space Heating Demand] -> [Space Heater] -> [Terminus]
      # [Heavy Oil 30%]        ->      ^        (skip edge)              (skip edge)
      #
      # This tests that weighted composition propagates correctly through the entire chain
      # and doesn't revert to carrier default value at intermediate nodes
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:buildings_space_heater_crude_oil, groups: [:emissions])
          builder.add(:buildings_final_demand_for_space_heating_crude_oil, groups: [:emissions])
          builder.add(:oil_blender, groups: [:emissions])
          builder.add(:conventional_oil, groups: [:primary_energy_demand], demand: 70)
          builder.add(:heavy_oil, groups: [:primary_energy_demand], demand: 30)

          # Multiple sources with different CO2 content blend at oil_blender
          builder.connect(:conventional_oil, :oil_blender, :crude_oil, type: :share)
          builder.connect(:heavy_oil, :oil_blender, :crude_oil_heavy, type: :share)

          # Blender to intermediate (with skip group)
          builder.connect(
            :oil_blender,
            :buildings_final_demand_for_space_heating_crude_oil,
            :crude_oil,
            type: :share,
            groups: [:emissions_skip_crude_oil_mix]
          )

          # Intermediate to consumer (with skip group)
          builder.connect(
            :buildings_final_demand_for_space_heating_crude_oil,
            :buildings_space_heater_crude_oil,
            :crude_oil,
            type: :share,
            groups: [:emissions_skip_crude_oil_mix]
          )

          # Consumer to terminus
          builder.connect(:buildings_space_heater_crude_oil, :terminus, :electricity, type: :share)

          # Conventional crude oil: 0.0733 kg CO2/MJ
          builder.carrier_attrs(:crude_oil, co2_conversion_per_mj: 0.0733)
          # Heavy crude oil: 0.0850 kg CO2/MJ (higher emissions)
          builder.carrier_attrs(:crude_oil_heavy, co2_conversion_per_mj: 0.0850)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:blender) { graph.node(:oil_blender) }
      let(:intermediate) { graph.node(:buildings_final_demand_for_space_heating_crude_oil) }
      let(:consumer) { graph.node(:buildings_space_heater_crude_oil) }

      it 'calculates blender input from mixed sources' do
        # Blender receives:
        # - 70 MJ conventional crude @ 0.0733 kg/MJ = 5.131 kg
        # - 30 MJ heavy crude @ 0.0850 kg/MJ = 2.55 kg
        # Total input: 7.681 kg CO2
        expect(blender).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.681)
      end

      it 'calculates blender output using weighted composition' do
        # Blender outputs 100 MJ crude_oil with skip group
        # Should use weighted composition (0.07681 kg/MJ), not carrier value (0.0733 kg/MJ)
        # 100 MJ * 0.07681 kg/MJ = 7.681 kg CO2
        expect(blender).to have_query_value(:direct_co2_output_content_carriers_fossil, 7.681)
      end

      it 'preserves mass balance at blender' do
        input = blender.query.direct_co2_input_content_carriers_fossil
        output = blender.query.direct_co2_output_content_carriers_fossil
        emissions = blender.query.direct_co2_output_production_emissions_fossil

        expect(input).to be_within(0.0000001).of(output)
        expect(emissions).to be_within(0.0000001).of(0.0)
      end

      it 'propagates weighted composition to intermediate node input' do
        # Intermediate receives weighted composition, not carrier default
        # 100 MJ * 0.07681 kg/MJ = 7.681 kg CO2
        expect(intermediate).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.681)
      end

      it 'propagates weighted composition to intermediate node output' do
        # Intermediate outputs weighted composition through skip edge
        expect(intermediate).to have_query_value(:direct_co2_output_content_carriers_fossil, 7.681)
      end

      it 'preserves mass balance at intermediate node' do
        input = intermediate.query.direct_co2_input_content_carriers_fossil
        output = intermediate.query.direct_co2_output_content_carriers_fossil
        emissions = intermediate.query.direct_co2_output_production_emissions_fossil

        expect(input).to be_within(0.0000001).of(output)
        expect(emissions).to be_within(0.0000001).of(0.0)
      end

      it 'propagates weighted composition to final consumer' do
        # Consumer receives weighted composition through entire chain
        # 100 MJ * 0.07681 kg/MJ = 7.681 kg CO2
        expect(consumer).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.681)
      end

      it 'shows correct production emissions at consumer' do
        # Consumer burns all input, producing emissions equal to input content
        # 7.681 kg CO2
        expect(consumer).to have_query_value(:direct_co2_output_production_emissions_fossil, 7.681)
      end
    end

    context 'with partial skip chain (edge case)' do
      # Create a chain where only the first edge has skip group:
      # [Crude Oil Producer] -> [Final Demand] -> [Space Heating Demand] -> [Space Heater] -> [Terminus]
      #                                           (skip edge)              (NO skip edge)
      #
      # This demonstrates the difference: without skip group on second edge,
      # it should use carrier default value
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:buildings_space_heater_crude_oil, groups: [:emissions])
          builder.add(:buildings_final_demand_for_space_heating_crude_oil, groups: [:emissions])
          builder.add(:buildings_final_demand_crude_oil, groups: [:emissions])
          builder.add(:crude_oil_producer, groups: [:primary_energy_demand])

          # Connect producer to final demand
          builder.connect(:crude_oil_producer, :buildings_final_demand_crude_oil, :crude_oil, type: :share)

          # Connect final demand to intermediate (WITH skip group)
          builder.connect(
            :buildings_final_demand_crude_oil,
            :buildings_final_demand_for_space_heating_crude_oil,
            :crude_oil,
            type: :share,
            groups: [:emissions_skip_crude_oil_mix]
          )

          # Connect intermediate to consumer (WITHOUT skip group)
          builder.connect(
            :buildings_final_demand_for_space_heating_crude_oil,
            :buildings_space_heater_crude_oil,
            :crude_oil,
            type: :share
          )

          # Connect consumer to terminus
          builder.connect(:buildings_space_heater_crude_oil, :terminus, :useable_heat, type: :share)

          builder.carrier_attrs(:crude_oil, co2_conversion_per_mj: 0.0733)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:intermediate) { graph.node(:buildings_final_demand_for_space_heating_crude_oil) }
      let(:consumer) { graph.node(:buildings_space_heater_crude_oil) }

      it 'calculates intermediate input using skip logic' do
        # First edge has skip group, so intermediate receives correct value
        expect(intermediate).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.33)
      end

      it 'calculates consumer input using carrier default (no skip)' do
        # Second edge does NOT have skip group, so it uses carrier default
        # This demonstrates that skip group must be on edge for special handling
        expect(consumer).to have_query_value(:direct_co2_input_content_carriers_fossil, 7.33)
      end

      it 'preserves mass balance at intermediate node' do
        input = intermediate.query.direct_co2_input_content_carriers_fossil
        output = intermediate.query.direct_co2_output_content_carriers_fossil
        emissions = intermediate.query.direct_co2_output_production_emissions_fossil

        expect(input).to be_within(0.0000001).of(output)
        expect(emissions).to be_within(0.0000001).of(0.0)
      end
    end

    context 'with no demand' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 0)
          builder.add(:power_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :power_plant, :coal, type: :share)
          builder.connect(:power_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:power_plant) { graph.node(:power_plant) }

      it 'returns zero when demand is zero' do
        expect(power_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end
    end

    context 'with carrier having no CO2 value' do
      # Some carriers may not have CO2 values defined
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:consumer, groups: [:emissions])
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :consumer, :custom_carrier, type: :share)
          builder.connect(:consumer, :terminus, :electricity, type: :share)

          # custom_carrier has no co2_conversion_per_mj set
        end
      end

      let(:graph) { builder.to_qernel }
      let(:consumer) { graph.node(:consumer) }

      it 'returns zero when carrier has no CO2 value' do
        expect(consumer).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end
    end
  end

  describe 'CO2 capture methods' do
    context 'with CCS plant capturing 85% of emissions' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:ccs_plant, groups: [:emissions], ccs_capture_rate: 0.85)
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :ccs_plant, :natural_gas, type: :share)
          builder.connect(:ccs_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:ccs_plant) { graph.node(:ccs_plant) }

      it 'calculates zero capture when output equals input' do
        # A (input): 100 MJ * 0.0564 kg/MJ = 5.64 kg CO2
        # C (output): 5.64 kg CO2 (electricity inherits from input)
        # Captured: (A + B - C) * 0.85 = (5.64 + 0 - 5.64) * 0.85 = 0 kg
        expect(ccs_plant).to have_query_value(:direct_co2_output_production_capture_fossil, 0.0)
      end

      it 'calculates biogenic CO2 captured as zero (no biogenic input)' do
        expect(ccs_plant).to have_query_value(:direct_co2_output_production_capture_biogenic, 0.0)
      end
    end

    context 'with no CCS (ccs_capture_rate = 0)' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 200)
          builder.add(:coal_plant, groups: [:emissions], ccs_capture_rate: 0.0)
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_plant) { graph.node(:coal_plant) }

      it 'has zero fossil captured emissions' do
        expect(coal_plant).to have_query_value(:direct_co2_output_production_capture_fossil, 0.0)
      end

      it 'has zero biogenic captured emissions' do
        expect(coal_plant).to have_query_value(:direct_co2_output_production_capture_biogenic, 0.0)
      end
    end

    context 'with nil ccs_capture_rate' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 150)
          builder.add(:plant, groups: [:emissions])
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :plant, :natural_gas, type: :share)
          builder.connect(:plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:plant) { graph.node(:plant) }

      it 'returns zero fossil captured emissions when capture rate not set' do
        expect(plant).to have_query_value(:direct_co2_output_production_capture_fossil, 0.0)
      end

      it 'returns zero biogenic captured emissions when capture rate not set' do
        expect(plant).to have_query_value(:direct_co2_output_production_capture_biogenic, 0.0)
      end
    end

    context 'with biogenic CO2 input' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:bio_plant, groups: [:emissions], ccs_capture_rate: 0.90)
          builder.add(:bio_producer, groups: [:primary_energy_demand])

          builder.connect(:bio_producer, :bio_plant, :biogenic_waste, type: :share)
          builder.connect(:bio_plant, :terminus, :steam_hot_water, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:bio_plant) { graph.node(:bio_plant) }

      it 'calculates zero capture when output equals input' do
        # A (input): 100 MJ * 0.06 kg/MJ = 6.0 kg CO2
        # C (output): 6.0 kg CO2 (steam inherits from input)
        # Captured: (A - C) * 0.90 = (6.0 - 6.0) * 0.90 = 0 kg
        expect(bio_plant).to have_query_value(:direct_co2_output_production_capture_biogenic, 0.0)
      end

      it 'has zero fossil captured emissions (no fossil input)' do
        expect(bio_plant).to have_query_value(:direct_co2_output_production_capture_fossil, 0.0)
      end
    end

    context 'with node not in emissions group' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:non_emissions_node, ccs_capture_rate: 0.85)
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :non_emissions_node, :natural_gas, type: :share)
          builder.connect(:non_emissions_node, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:non_emissions_node) { graph.node(:non_emissions_node) }

      it 'returns nil for fossil capture when not in emissions group' do
        expect(non_emissions_node.query.direct_co2_output_production_capture_fossil).to be_nil
      end

      it 'returns nil for biogenic capture when not in emissions group' do
        expect(non_emissions_node.query.direct_co2_output_production_capture_biogenic).to be_nil
      end
    end

    context 'with mixed carrier inputs (network gas blending)' do
      # Create a graph modeling network gas distribution:
      # [Natural Gas Producer] ---70%---> [Network Gas Distributor] -> [Gas Burner] -> [Terminus]
      # [Green Gas Producer]   ---30%--^
      # Tests weighted average composition: 70% natural gas (0.0564 kg/MJ) + 30% green gas (0.0 kg/MJ)
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:gas_burner, groups: [:emissions])
          builder.add(:network_gas_distributor, groups: [:emissions])
          builder.add(:natural_gas_producer, groups: [:primary_energy_demand], demand: 70)
          builder.add(:green_gas_producer, groups: [:primary_energy_demand], demand: 30)

          # Network gas distributor receives from two sources
          builder.connect(:natural_gas_producer, :network_gas_distributor, :natural_gas,
            type: :share)
          builder.connect(:green_gas_producer, :network_gas_distributor, :green_gas, type: :share)

          # Distributor supplies burner with mixed network gas (nil co2 value - uses recursion)
          builder.connect(:network_gas_distributor, :gas_burner, :network_gas, type: :share)
          builder.connect(:gas_burner, :terminus, :useable_heat, type: :share)

          # Define carrier CO2 values
          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
          builder.carrier_attrs(:green_gas, co2_conversion_per_mj: 0.0)
          builder.carrier_attrs(:network_gas, co2_conversion_per_mj: nil) # Forces recursion
        end
      end

      let(:graph) { builder.to_qernel }
      let(:gas_burner) { graph.node(:gas_burner) }
      let(:distributor) { graph.node(:network_gas_distributor) }

      it 'uses the mixed composition for downstream emissions calculation' do
        # Gas burner receives 100 MJ network gas with 0.03948 kg/MJ composition
        # Total emissions: 100 * 0.03948 = 3.948 kg CO2
        expect(gas_burner).to have_query_value(:direct_co2_input_content_carriers_fossil, 3.948)
      end
    end
  end

  describe 'secondary energy carriers (no combustion at consumer)' do
    # Tests that secondary carriers (electricity, steam, heat) show zero direct emissions
    # at the consumer, with emissions tracked only at the combustion point (power plant, CHP, etc.)
    context 'with electricity from coal plant' do
      # Create a graph:
      # [Coal Producer] -> [Coal Plant] -> [Electric Heater] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:electric_heater, groups: [:emissions])
          builder.add(:coal_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :electric_heater, :electricity, type: :share)
          builder.connect(:electric_heater, :terminus, :useable_heat, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_plant) { graph.node(:coal_plant) }
      let(:electric_heater) { graph.node(:electric_heater) }

      it 'shows direct emissions only at coal plant (combustion point)' do
        # 100 MJ coal * 0.09 kg/MJ = 9.0 kg CO2 at combustion
        expect(coal_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 9.0)
      end

      it 'shows zero direct emissions at electric heater (no combustion)' do
        # Electricity is secondary carrier - consumer does not combust anything
        expect(electric_heater).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end
    end

    context 'with steam_hot_water from gas CHP' do
      # Create a graph:
      # [Gas Producer] -> [Gas CHP] -> [Steam Consumer] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:steam_consumer, groups: [:emissions])
          builder.add(:gas_chp, groups: [:emissions])
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :gas_chp, :natural_gas, type: :share)
          builder.connect(:gas_chp, :steam_consumer, :steam_hot_water, type: :share)
          builder.connect(:steam_consumer, :terminus, :useable_heat, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
          builder.carrier_attrs(:steam_hot_water, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:gas_chp) { graph.node(:gas_chp) }
      let(:steam_consumer) { graph.node(:steam_consumer) }

      it 'shows direct emissions only at CHP (combustion point)' do
        # 50 MJ gas * 0.0564 kg/MJ = 2.82 kg CO2 at combustion
        expect(gas_chp).to have_query_value(:direct_co2_input_content_carriers_fossil, 2.82)
      end

      it 'shows zero direct emissions at steam consumer (no combustion)' do
        # Steam is secondary carrier - consumer does not combust anything
        expect(steam_consumer).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end
    end

    context 'with hot_water from boiler' do
      # Create a graph:
      # [Coal Producer] -> [Boiler] -> [Hot Water Heater] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 75)
          builder.add(:hot_water_heater, groups: [:emissions])
          builder.add(:boiler, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :boiler, :coal, type: :share)
          builder.connect(:boiler, :hot_water_heater, :hot_water, type: :share)
          builder.connect(:hot_water_heater, :terminus, :useable_heat, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
          builder.carrier_attrs(:hot_water, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:boiler) { graph.node(:boiler) }
      let(:hot_water_heater) { graph.node(:hot_water_heater) }

      it 'shows direct emissions only at boiler (combustion point)' do
        # 75 MJ coal * 0.09 kg/MJ = 6.75 kg CO2 at combustion
        expect(boiler).to have_query_value(:direct_co2_input_content_carriers_fossil, 6.75)
      end

      it 'shows zero direct emissions at hot water heater (no combustion)' do
        # Hot water is secondary carrier - consumer does not combust anything
        expect(hot_water_heater).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end
    end

    context 'with imported_electricity' do
      # Create a graph:
      # [Electricity Import] -> [Data Center] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 200)
          builder.add(:data_center, groups: [:emissions])
          builder.add(:electricity_import, groups: [:primary_energy_demand])

          builder.connect(:electricity_import, :data_center, :imported_electricity, type: :share)
          builder.connect(:data_center, :terminus, :computing, type: :share)

          builder.carrier_attrs(:imported_electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:data_center) { graph.node(:data_center) }

      it 'shows zero direct emissions at imported electricity consumer' do
        # Imported electricity is secondary carrier - no local combustion
        expect(data_center).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.0)
      end
    end
  end

  describe 'nodes without emissions group' do
    # Verify that nodes without the :emissions group return nil instead of raising errors
    context 'when a node does not have the emissions group' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:non_emissions_node)
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :non_emissions_node, :electricity, type: :share)
          builder.connect(:non_emissions_node, :terminus, :electricity, type: :share)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:non_emissions_node) { graph.node(:non_emissions_node) }

      it 'returns nil for direct_co2_input_content_carriers_fossil' do
        expect(non_emissions_node.query.direct_co2_input_content_carriers_fossil).to be_nil
      end

      it 'returns nil for direct_co2_output_content_carriers_fossil' do
        expect(non_emissions_node.query.direct_co2_output_content_carriers_fossil).to be_nil
      end

      it 'returns nil for direct_co2_output_production_emissions_fossil' do
        expect(non_emissions_node.query.direct_co2_output_production_emissions_fossil).to be_nil
      end

      it 'returns nil for direct_reporting_emissions_co2_production' do
        expect(non_emissions_node.query.direct_reporting_emissions_co2_production).to be_nil
      end

      it 'returns nil for direct_co2_input_content_carriers_biogenic' do
        expect(non_emissions_node.query.direct_co2_input_content_carriers_biogenic).to be_nil
      end

      it 'returns nil for direct_co2_output_content_carriers_biogenic' do
        expect(non_emissions_node.query.direct_co2_output_content_carriers_biogenic).to be_nil
      end

      it 'returns nil for direct_co2_output_production_emissions_biogenic' do
        expect(non_emissions_node.query.direct_co2_output_production_emissions_biogenic).to be_nil
      end
    end
  end

  describe '#direct_co2_input_content_carriers_biogenic' do
    context 'with a pure biogenic carrier (biogenic_waste)' do
      # Create a simple graph:
      # [Biogenic Waste Producer] -> [Waste Burner] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:waste_burner, groups: [:emissions])
          builder.add(:biogenic_waste_producer, groups: [:primary_energy_demand])

          builder.connect(:biogenic_waste_producer, :waste_burner, :biogenic_waste, type: :share)
          builder.connect(:waste_burner, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:waste_burner) { graph.node(:waste_burner) }

      it 'calculates biogenic emissions from biogenic_waste input' do
        # 100 MJ * 0.06 kg/MJ = 6.0 kg biogenic CO2
        expect(waste_burner).to have_query_value(:direct_co2_input_content_carriers_biogenic, 6.0)
      end
    end

    context 'with secondary carriers (electricity from biogenic)' do
      # Create a graph:
      # [Biogenic Waste Producer] -> [Waste Plant] -> [Electric Heater] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:electric_heater, groups: [:emissions])
          builder.add(:waste_plant, groups: [:emissions])
          builder.add(:biogenic_waste_producer, groups: [:primary_energy_demand])

          builder.connect(:biogenic_waste_producer, :waste_plant, :biogenic_waste, type: :share)
          builder.connect(:waste_plant, :electric_heater, :electricity, type: :share)
          builder.connect(:electric_heater, :terminus, :heat, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
          builder.carrier_attrs(:electricity, potential_co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:electric_heater) { graph.node(:electric_heater) }
      let(:waste_plant) { graph.node(:waste_plant) }

      it 'returns zero for electricity consumer (no biogenic emissions)' do
        # Electricity has no biogenic carbon content
        expect(electric_heater).to have_query_value(:direct_co2_input_content_carriers_biogenic, 0.0)
      end

      it 'shows biogenic emissions at the waste plant' do
        # 50 MJ * 0.06 kg/MJ = 3.0 kg biogenic CO2
        expect(waste_plant).to have_query_value(:direct_co2_input_content_carriers_biogenic, 3.0)
      end
    end

    context 'with mixed biogenic carriers (skip carrier value)' do
      # Create a graph that blends different biogenic sources:
      # [Wood Waste (60 MJ)] -> [Biogenic Blender] -> [Burner] -> [Terminus]
      # [Green Waste (40 MJ)] ->       ^
      #
      # Edge from blender to burner is marked to skip carrier value
      # and calculate composition from the supply mix instead
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:burner, groups: [:emissions])
          builder.add(:biogenic_blender, groups: [:emissions])
          builder.add(:wood_waste, groups: [:primary_energy_demand], demand: 60)
          builder.add(:green_waste, groups: [:primary_energy_demand], demand: 40)

          # Biogenic sources with different CO2 content
          builder.connect(:wood_waste, :biogenic_blender, :wood_pellets, type: :share)
          builder.connect(:green_waste, :biogenic_blender, :green_waste_carrier, type: :share)

          # Edge marked to skip carrier value and calculate from mix
          builder.connect(:biogenic_blender, :burner, :biogenic_waste, type: :share, groups: [:emissions_skip_crude_oil_mix])
          builder.connect(:burner, :terminus, :electricity, type: :share)

          # Wood pellets: 0.07 kg biogenic CO2/MJ
          builder.carrier_attrs(:wood_pellets, potential_co2_conversion_per_mj: 0.07)
          # Green waste: 0.05 kg biogenic CO2/MJ
          builder.carrier_attrs(:green_waste_carrier, potential_co2_conversion_per_mj: 0.05)
          # Biogenic waste carrier default (should be skipped)
          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:burner) { graph.node(:burner) }
      let(:biogenic_blender) { graph.node(:biogenic_blender) }

      it 'calculates burner input from supply mix, not carrier value' do
        # Expected: weighted average based on supply mix
        # (60 * 0.07 + 40 * 0.05) / 100 = 0.062 kg biogenic CO2/MJ
        # 100 MJ * 0.062 kg/MJ = 6.2 kg biogenic CO2
        expect(burner).to have_query_value(:direct_co2_input_content_carriers_biogenic, 6.2)
      end

      it 'calculates blender input content from mixed sources' do
        # Blender receives:
        # - 60 MJ wood pellets @ 0.07 kg/MJ = 4.2 kg
        # - 40 MJ green waste @ 0.05 kg/MJ = 2.0 kg
        # Total input: 6.2 kg biogenic CO2
        expect(biogenic_blender).to have_query_value(:direct_co2_input_content_carriers_biogenic, 6.2)
      end

      it 'calculates blender output content using weighted composition' do
        # Blender outputs 100 MJ biogenic_waste with skip group
        # Should use weighted composition (0.062 kg/MJ), not carrier value (0.06 kg/MJ)
        # 100 MJ * 0.062 kg/MJ = 6.2 kg biogenic CO2
        expect(biogenic_blender).to have_query_value(:direct_co2_output_content_carriers_biogenic, 6.2)
      end

      it 'preserves mass balance at blender (pass-through node)' do
        # For a pass-through blender: A (input) - C (output) = E (emissions)
        # Since no combustion occurs: E should be 0
        # Therefore: A should equal C
        input = biogenic_blender.query.direct_co2_input_content_carriers_biogenic
        output = biogenic_blender.query.direct_co2_output_content_carriers_biogenic
        emissions = biogenic_blender.query.direct_co2_output_production_emissions_biogenic

        expect(input).to be_within(0.0000001).of(output)
        expect(emissions).to be_within(0.0000001).of(0.0)
      end
    end

    context 'with no demand' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 0)
          builder.add(:waste_burner, groups: [:emissions])
          builder.add(:biogenic_waste_producer, groups: [:primary_energy_demand])

          builder.connect(:biogenic_waste_producer, :waste_burner, :biogenic_waste, type: :share)
          builder.connect(:waste_burner, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:waste_burner) { graph.node(:waste_burner) }

      it 'returns zero when demand is zero' do
        expect(waste_burner).to have_query_value(:direct_co2_input_content_carriers_biogenic, 0.0)
      end
    end

    context 'with carrier having no potential CO2 value' do
      # Some carriers may not have potential_co2_conversion_per_mj defined
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:consumer, groups: [:emissions])
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :consumer, :custom_carrier, type: :share)
          builder.connect(:consumer, :terminus, :electricity, type: :share)

          # custom_carrier has no potential_co2_conversion_per_mj set
        end
      end

      let(:graph) { builder.to_qernel }
      let(:consumer) { graph.node(:consumer) }

      it 'returns zero when carrier has no potential biogenic CO2 value' do
        expect(consumer).to have_query_value(:direct_co2_input_content_carriers_biogenic, 0.0)
      end
    end
  end

  describe '#direct_co2_output_content_carriers_biogenic' do
    context 'with pure biogenic carrier output' do
      # Create a graph:
      # [Biogenic Producer] -> [Processor] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:processor, groups: [:emissions])
          builder.add(:biogenic_producer, groups: [:primary_energy_demand])

          builder.connect(:biogenic_producer, :processor, :biogenic_waste, type: :share)
          builder.connect(:processor, :terminus, :biogenic_waste, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:processor) { graph.node(:processor) }

      it 'calculates output biogenic content correctly' do
        # 100 MJ * 0.06 kg/MJ = 6.0 kg biogenic CO2
        expect(processor).to have_query_value(:direct_co2_output_content_carriers_biogenic, 6.0)
      end

      it 'preserves mass balance (pass-through)' do
        input = processor.query.direct_co2_input_content_carriers_biogenic
        output = processor.query.direct_co2_output_content_carriers_biogenic

        expect(input).to be_within(0.0000001).of(output)
      end
    end
  end

  describe '#direct_co2_output_production_emissions_biogenic' do
    context 'with biogenic combustion' do
      # Create a graph:
      # [Biogenic Waste Producer] -> [Waste Burner] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:waste_burner, groups: [:emissions])
          builder.add(:biogenic_waste_producer, groups: [:primary_energy_demand])

          builder.connect(:biogenic_waste_producer, :waste_burner, :biogenic_waste, type: :share)
          builder.connect(:waste_burner, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
          builder.carrier_attrs(:electricity, potential_co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:waste_burner) { graph.node(:waste_burner) }

      it 'calculates biogenic production emissions correctly' do
        # Input: 100 MJ * 0.06 kg/MJ = 6.0 kg biogenic CO2
        # Output: electricity has 0 biogenic content
        # Emissions: 6.0 - 0 = 6.0 kg biogenic CO2
        expect(waste_burner).to have_query_value(:direct_co2_output_production_emissions_biogenic, 6.0)
      end

      it 'validates mass balance equation A - C = E' do
        input = waste_burner.query.direct_co2_input_content_carriers_biogenic
        output = waste_burner.query.direct_co2_output_content_carriers_biogenic
        emissions = waste_burner.query.direct_co2_output_production_emissions_biogenic

        expect(emissions).to be_within(0.0000001).of(input - output)
      end
    end

    context 'with biogenic pass-through node' do
      # Create a graph:
      # [Biogenic Producer] -> [Distributor] -> [Consumer] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:consumer, groups: [:emissions])
          builder.add(:distributor, groups: [:emissions])
          builder.add(:biogenic_producer, groups: [:primary_energy_demand])

          builder.connect(:biogenic_producer, :distributor, :biogenic_waste, type: :share)
          builder.connect(:distributor, :consumer, :biogenic_waste, type: :share)
          builder.connect(:consumer, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
          builder.carrier_attrs(:electricity, potential_co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:distributor) { graph.node(:distributor) }
      let(:consumer) { graph.node(:consumer) }

      it 'shows zero emissions at pass-through distributor' do
        # Pass-through node: input = output, emissions = 0
        expect(distributor).to have_query_value(:direct_co2_output_production_emissions_biogenic, 0.0)
      end

      it 'shows emissions at consumer (combustion point)' do
        # Consumer burns the biogenic fuel
        # 100 MJ * 0.06 kg/MJ = 6.0 kg biogenic CO2
        expect(consumer).to have_query_value(:direct_co2_output_production_emissions_biogenic, 6.0)
      end
    end
  end

  describe '#direct_co2_input_utilisation_fossil' do
    context 'with node having co2_utilisation_per_mj attribute' do
      # Create a graph:
      # [Gas Producer] -> [Synfuel Plant] -> [Terminus]
      # Synfuel plant utilises CO2 as feedstock
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:synfuel_plant, groups: [:emissions], co2_utilisation_per_mj: 0.02)
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :synfuel_plant, :natural_gas, type: :share)
          builder.connect(:synfuel_plant, :terminus, :diesel, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:synfuel_plant) { graph.node(:synfuel_plant) }

      it 'calculates CO2 utilisation from total output energy' do
        # Total output: 100 MJ diesel
        # Utilisation rate: 0.02 kg CO2/MJ
        # Total utilised: 100 * 0.02 = 2.0 kg CO2
        expect(synfuel_plant).to have_query_value(:direct_co2_input_utilisation_fossil, 2.0)
      end
    end

    context 'with node having multiple output edges' do
      # Create a graph:
      # [Gas Producer] -> [CHP Plant] -> [Electric Consumer]
      #                       |
      #                       +--------> [Heat Consumer]
      # CHP plant outputs both electricity and heat
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:heat_consumer, demand: 60)
          builder.add(:electric_consumer, demand: 40)
          builder.add(:chp_plant, groups: [:emissions], co2_utilisation_per_mj: 0.01)
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :chp_plant, :natural_gas, type: :share)
          builder.connect(:chp_plant, :electric_consumer, :electricity, type: :share)
          builder.connect(:chp_plant, :heat_consumer, :steam_hot_water, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:chp_plant) { graph.node(:chp_plant) }

      it 'sums utilisation across all output edges' do
        # Total output: 40 MJ electricity + 60 MJ heat = 100 MJ
        # Utilisation rate: 0.01 kg CO2/MJ
        # Total utilised: 100 * 0.01 = 1.0 kg CO2
        expect(chp_plant).to have_query_value(:direct_co2_input_utilisation_fossil, 1.0)
      end
    end

    context 'with node without co2_utilisation_per_mj attribute' do
      # Create a graph:
      # [Coal Producer] -> [Power Plant] -> [Terminus]
      # Power plant does not utilise CO2
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:power_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :power_plant, :coal, type: :share)
          builder.connect(:power_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:power_plant) { graph.node(:power_plant) }

      it 'returns zero when co2_utilisation_per_mj is not set' do
        expect(power_plant).to have_query_value(:direct_co2_input_utilisation_fossil, 0.0)
      end
    end

    context 'with node without emissions group' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:non_emissions_node, co2_utilisation_per_mj: 0.02)
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :non_emissions_node, :electricity, type: :share)
          builder.connect(:non_emissions_node, :terminus, :electricity, type: :share)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:non_emissions_node) { graph.node(:non_emissions_node) }

      it 'returns nil for direct_co2_input_utilisation_fossil' do
        expect(non_emissions_node.query.direct_co2_input_utilisation_fossil).to be_nil
      end
    end

    context 'with zero demand' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 0)
          builder.add(:synfuel_plant, groups: [:emissions], co2_utilisation_per_mj: 0.02)
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :synfuel_plant, :natural_gas, type: :share)
          builder.connect(:synfuel_plant, :terminus, :diesel, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:synfuel_plant) { graph.node(:synfuel_plant) }

      it 'returns zero when demand is zero' do
        expect(synfuel_plant).to have_query_value(:direct_co2_input_utilisation_fossil, 0.0)
      end
    end

    context 'with high utilisation rate' do
      # Create a graph:
      # [Methanol Producer] -> [Methanol Plant] -> [Terminus]
      # Plant utilises significant CO2 for methanol synthesis
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:methanol_plant, groups: [:emissions], co2_utilisation_per_mj: 0.15)
          builder.add(:methanol_producer, groups: [:primary_energy_demand])

          builder.connect(:methanol_producer, :methanol_plant, :hydrogen, type: :share)
          builder.connect(:methanol_plant, :terminus, :methanol, type: :share)

          builder.carrier_attrs(:hydrogen, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:methanol_plant) { graph.node(:methanol_plant) }

      it 'calculates high utilisation correctly' do
        # Total output: 50 MJ methanol
        # Utilisation rate: 0.15 kg CO2/MJ
        # Total utilised: 50 * 0.15 = 7.5 kg CO2
        expect(methanol_plant).to have_query_value(:direct_co2_input_utilisation_fossil, 7.5)
      end
    end
  end

  describe 'emissions with CO2 utilisation (CCU/CCR nodes)' do
    context 'with CCU node utilising CO2 as feedstock' do
      # Create a graph:
      # [Gas Producer] -> [Synfuel Plant] -> [Terminus]
      # Synfuel plant utilises CO2 in product synthesis
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:synfuel_plant, groups: [:emissions], co2_utilisation_per_mj: 0.02)
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :synfuel_plant, :natural_gas, type: :share)
          builder.connect(:synfuel_plant, :terminus, :diesel, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
          builder.carrier_attrs(:diesel, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:synfuel_plant) { graph.node(:synfuel_plant) }

      it 'calculates input content correctly' do
        # 100 MJ gas * 0.0564 kg/MJ = 5.64 kg CO2
        expect(synfuel_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 5.64)
      end

      it 'calculates output content correctly' do
        # Diesel has 0 CO2 content
        expect(synfuel_plant).to have_query_value(:direct_co2_output_content_carriers_fossil, 0.0)
      end

      it 'calculates utilisation correctly' do
        # 100 MJ output * 0.02 kg/MJ = 2.0 kg CO2 utilised
        expect(synfuel_plant).to have_query_value(:direct_co2_input_utilisation_fossil, 2.0)
      end

      it 'adds utilisation to input in production emissions' do
        # Mass balance: E = A + U - C
        # E = 5.64 + 2.0 - 0 = 7.64 kg CO2
        expect(synfuel_plant).to have_query_value(:direct_co2_output_production_emissions_fossil, 7.64)
      end

      it 'validates complete mass balance equation A + U - C = E' do
        input = synfuel_plant.query.direct_co2_input_content_carriers_fossil
        output = synfuel_plant.query.direct_co2_output_content_carriers_fossil
        utilisation = synfuel_plant.query.direct_co2_input_utilisation_fossil
        emissions = synfuel_plant.query.direct_co2_output_production_emissions_fossil

        expect(emissions).to be_within(0.0000001).of(input + utilisation - output)
      end

      it 'reporting method reflects net emissions after utilisation' do
        production = synfuel_plant.query.direct_co2_output_production_emissions_fossil
        reporting = synfuel_plant.query.direct_reporting_emissions_co2_production

        expect(reporting).to eq(production)
        expect(reporting).to be_within(0.0000001).of(7.64)
      end
    end

    context 'with high utilisation rate (methanol synthesis)' do
      # Create a graph:
      # [Hydrogen Producer] -> [Methanol Plant] -> [Terminus]
      # Methanol synthesis utilises significant CO2
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:methanol_plant, groups: [:emissions], co2_utilisation_per_mj: 0.08)
          builder.add(:hydrogen_producer, groups: [:primary_energy_demand])

          builder.connect(:hydrogen_producer, :methanol_plant, :hydrogen, type: :share)
          builder.connect(:methanol_plant, :terminus, :methanol, type: :share)

          builder.carrier_attrs(:hydrogen, co2_conversion_per_mj: 0.0)
          builder.carrier_attrs(:methanol, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:methanol_plant) { graph.node(:methanol_plant) }

      it 'calculates high utilisation correctly' do
        # 100 MJ output * 0.08 kg/MJ = 8.0 kg CO2 utilised
        expect(methanol_plant).to have_query_value(:direct_co2_input_utilisation_fossil, 8.0)
      end

      it 'shows positive emissions when utilisation brings in external CO2' do
        # Input: 0 kg (hydrogen has no CO2)
        # Output: 0 kg
        # Utilisation: 8.0 kg (CO2 sourced externally and brought in as feedstock)
        # Emissions: 0 + 8.0 - 0 = 8.0 kg
        expect(methanol_plant).to have_query_value(:direct_co2_output_production_emissions_fossil, 8.0)
      end

      it 'validates mass balance with external CO2 input' do
        input = methanol_plant.query.direct_co2_input_content_carriers_fossil
        output = methanol_plant.query.direct_co2_output_content_carriers_fossil
        utilisation = methanol_plant.query.direct_co2_input_utilisation_fossil
        emissions = methanol_plant.query.direct_co2_output_production_emissions_fossil

        expect(emissions).to be_within(0.0000001).of(input + utilisation - output)
        expect(emissions).to eq(8.0)
      end
    end

    context 'with backward compatibility (node without utilisation)' do
      # Create a graph:
      # [Coal Producer] -> [Power Plant] -> [Terminus]
      # Traditional combustion plant (no CCU)
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:power_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :power_plant, :coal, type: :share)
          builder.connect(:power_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:power_plant) { graph.node(:power_plant) }

      it 'has zero utilisation' do
        expect(power_plant).to have_query_value(:direct_co2_input_utilisation_fossil, 0.0)
      end

      it 'calculates emissions correctly without utilisation (U = 0)' do
        # Input: 100 MJ * 0.09 kg/MJ = 9.0 kg CO2
        # Output: 0 kg (electricity has no CO2)
        # Utilisation: 0 kg (no CCU)
        # Emissions: 9.0 - 0 - 0 = 9.0 kg CO2
        expect(power_plant).to have_query_value(:direct_co2_output_production_emissions_fossil, 9.0)
      end

      it 'validates traditional mass balance equation A - C = E (when U = 0)' do
        input = power_plant.query.direct_co2_input_content_carriers_fossil
        output = power_plant.query.direct_co2_output_content_carriers_fossil
        emissions = power_plant.query.direct_co2_output_production_emissions_fossil

        # When utilisation is 0, E = A - C (traditional equation)
        expect(emissions).to be_within(0.0000001).of(input - output)
        expect(emissions).to eq(9.0)
      end

      it 'reporting method works correctly without utilisation' do
        expect(power_plant).to have_query_value(:direct_reporting_emissions_co2_production, 9.0)
      end
    end

    context 'with CCU node having both carbon output and utilisation' do
      # Create a graph:
      # [Gas Producer] -> [CCU Plant] -> [Terminus]
      # Plant outputs carbon-containing product AND utilises CO2
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 80)
          builder.add(:ccu_plant, groups: [:emissions], co2_utilisation_per_mj: 0.03)
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :ccu_plant, :natural_gas, type: :share)
          builder.connect(:ccu_plant, :terminus, :diesel, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
          builder.carrier_attrs(:diesel, co2_conversion_per_mj: 0.0733) # diesel contains carbon
        end
      end

      let(:graph) { builder.to_qernel }
      let(:ccu_plant) { graph.node(:ccu_plant) }

      it 'accounts for both output carbon content and utilisation' do
        # Input: 80 MJ * 0.0564 kg/MJ = 4.512 kg CO2
        # Output: 80 MJ * 0.0733 kg/MJ = 5.864 kg CO2
        # Utilisation: 80 MJ * 0.03 kg/MJ = 2.4 kg CO2 (brought in externally)
        # Emissions: 4.512 + 2.4 - 5.864 = 1.048 kg CO2
        expect(ccu_plant).to have_query_value(:direct_co2_output_production_emissions_fossil, 1.048)
      end

      it 'validates mass balance with carbon outputs and utilisation' do
        input = ccu_plant.query.direct_co2_input_content_carriers_fossil
        output = ccu_plant.query.direct_co2_output_content_carriers_fossil
        utilisation = ccu_plant.query.direct_co2_input_utilisation_fossil
        emissions = ccu_plant.query.direct_co2_output_production_emissions_fossil

        expect(input).to be_within(0.0001).of(4.512)
        expect(output).to be_within(0.0001).of(5.864)
        expect(utilisation).to eq(2.4)
        expect(emissions).to be_within(0.0001).of(input + utilisation - output)
      end
    end

    context 'with multiple CCU plants in series' do
      # Create a graph:
      # [Gas Producer] -> [CCU Plant 1] -> [CCU Plant 2] -> [Terminus]
      # Both plants utilise CO2
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:ccu_plant_2, groups: [:emissions], co2_utilisation_per_mj: 0.01)
          builder.add(:ccu_plant_1, groups: [:emissions], co2_utilisation_per_mj: 0.02)
          builder.add(:gas_producer, groups: [:primary_energy_demand])

          builder.connect(:gas_producer, :ccu_plant_1, :natural_gas, type: :share)
          builder.connect(:ccu_plant_1, :ccu_plant_2, :intermediate_fuel, type: :share)
          builder.connect(:ccu_plant_2, :terminus, :final_product, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
          builder.carrier_attrs(:intermediate_fuel, co2_conversion_per_mj: 0.0)
          builder.carrier_attrs(:final_product, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:ccu_plant_1) { graph.node(:ccu_plant_1) }
      let(:ccu_plant_2) { graph.node(:ccu_plant_2) }

      it 'calculates utilisation independently at each plant' do
        # Plant 1: 50 MJ * 0.02 kg/MJ = 1.0 kg CO2 utilised
        expect(ccu_plant_1).to have_query_value(:direct_co2_input_utilisation_fossil, 1.0)

        # Plant 2: 50 MJ * 0.01 kg/MJ = 0.5 kg CO2 utilised
        expect(ccu_plant_2).to have_query_value(:direct_co2_input_utilisation_fossil, 0.5)
      end

      it 'calculates emissions correctly at first plant' do
        # Plant 1: E = 2.82 + 1.0 - 0 = 3.82 kg CO2
        expect(ccu_plant_1).to have_query_value(:direct_co2_output_production_emissions_fossil, 3.82)
      end

      it 'calculates emissions correctly at second plant' do
        # Plant 2: E = 0 + 0.5 - 0 = 0.5 kg CO2
        expect(ccu_plant_2).to have_query_value(:direct_co2_output_production_emissions_fossil, 0.5)
      end

      it 'validates mass balance at each plant independently' do
        # Plant 1 mass balance
        input_1 = ccu_plant_1.query.direct_co2_input_content_carriers_fossil
        output_1 = ccu_plant_1.query.direct_co2_output_content_carriers_fossil
        utilisation_1 = ccu_plant_1.query.direct_co2_input_utilisation_fossil
        emissions_1 = ccu_plant_1.query.direct_co2_output_production_emissions_fossil

        expect(emissions_1).to be_within(0.0000001).of(input_1 + utilisation_1 - output_1)

        # Plant 2 mass balance
        input_2 = ccu_plant_2.query.direct_co2_input_content_carriers_fossil
        output_2 = ccu_plant_2.query.direct_co2_output_content_carriers_fossil
        utilisation_2 = ccu_plant_2.query.direct_co2_input_utilisation_fossil
        emissions_2 = ccu_plant_2.query.direct_co2_output_production_emissions_fossil

        expect(emissions_2).to be_within(0.0000001).of(input_2 + utilisation_2 - output_2)
      end
    end
  end

  describe '#direct_reporting_emissions_co2_production' do
    context 'with mixed fossil and biogenic inputs' do
      # Create a graph:
      # [Gas Producer] -> [Mixed Combustion Plant] <- [Biogenic Waste Producer]
      #                           |
      #                           v
      #                       [Terminus]
      # Plant burns both natural gas (fossil) and biogenic waste
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:mixed_combustion_plant, groups: [:emissions])
          builder.add(:gas_producer, groups: [:primary_energy_demand], demand: 60)
          builder.add(:biogenic_waste_producer, groups: [:primary_energy_demand], demand: 40)

          builder.connect(:gas_producer, :mixed_combustion_plant, :natural_gas, type: :share)
          builder.connect(:biogenic_waste_producer, :mixed_combustion_plant, :biogenic_waste, type: :share)
          builder.connect(:mixed_combustion_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0, potential_co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:mixed_plant) { graph.node(:mixed_combustion_plant) }

      it 'reports fossil production emissions only' do
        # Fossil: 60 MJ * 0.0564 kg/MJ = 3.384 kg CO2
        # Biogenic: 40 MJ * 0.06 kg/MJ = 2.4 kg CO2 (not included in reporting)
        # Reporting (fossil only): 3.384 kg CO2
        expect(mixed_plant).to have_query_value(:direct_reporting_emissions_co2_production, 3.384)
      end

      it 'fossil component matches fossil production emissions' do
        fossil = mixed_plant.query.direct_co2_output_production_emissions_fossil
        expect(fossil).to be_within(0.0001).of(3.384)
      end

      it 'biogenic component matches biogenic production emissions' do
        biogenic = mixed_plant.query.direct_co2_output_production_emissions_biogenic
        expect(biogenic).to be_within(0.0001).of(2.4)
      end

      it 'reporting equals fossil component only' do
        fossil = mixed_plant.query.direct_co2_output_production_emissions_fossil
        reporting = mixed_plant.query.direct_reporting_emissions_co2_production

        expect(reporting).to be_within(0.0001).of(fossil)
      end
    end

    context 'with biogenic-only input' do
      # Create a graph:
      # [Biogenic Waste Producer] -> [Waste Burner] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 150)
          builder.add(:waste_burner, groups: [:emissions])
          builder.add(:biogenic_waste_producer, groups: [:primary_energy_demand])

          builder.connect(:biogenic_waste_producer, :waste_burner, :biogenic_waste, type: :share)
          builder.connect(:waste_burner, :terminus, :steam_hot_water, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
          builder.carrier_attrs(:steam_hot_water, potential_co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:waste_burner) { graph.node(:waste_burner) }

      it 'reports zero when fossil is zero (fossil-only reporting)' do
        # Fossil: 0 kg CO2
        # Biogenic: 150 MJ * 0.06 kg/MJ = 9.0 kg CO2 (not included in reporting)
        # Reporting (fossil only): 0 kg CO2
        expect(waste_burner).to have_query_value(:direct_reporting_emissions_co2_production, 0.0)
      end

      it 'has zero fossil production emissions' do
        expect(waste_burner).to have_query_value(:direct_co2_output_production_emissions_fossil, 0.0)
      end

      it 'has non-zero biogenic production emissions' do
        expect(waste_burner).to have_query_value(:direct_co2_output_production_emissions_biogenic, 9.0)
      end

      it 'reporting equals fossil component (zero)' do
        fossil = waste_burner.query.direct_co2_output_production_emissions_fossil
        reporting = waste_burner.query.direct_reporting_emissions_co2_production

        expect(reporting).to eq(fossil)
      end
    end

    context 'with CCS capturing from mixed fossil and biogenic inputs' do
      # Create a graph:
      # [Gas Producer] -> [CCS Plant with Mixed Fuels] <- [Biogenic Waste Producer]
      #                           |
      #                           v
      #                       [Terminus]
      # CCS plant captures from both fossil and biogenic sources
      # NOTE: Electricity carrier doesn't set CO2 values, so it inherits from supply mix
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:ccs_mixed_plant, groups: [:emissions], ccs_capture_rate: 0.90)
          builder.add(:gas_producer, groups: [:primary_energy_demand], demand: 50)
          builder.add(:biogenic_waste_producer, groups: [:primary_energy_demand], demand: 50)

          builder.connect(:gas_producer, :ccs_mixed_plant, :natural_gas, type: :share)
          builder.connect(:biogenic_waste_producer, :ccs_mixed_plant, :biogenic_waste, type: :share)
          builder.connect(:ccs_mixed_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:natural_gas, co2_conversion_per_mj: 0.0564)
          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
          # electricity carrier not set - inherits CO2 from supply mix
        end
      end

      let(:graph) { builder.to_qernel }
      let(:ccs_mixed_plant) { graph.node(:ccs_mixed_plant) }

      it 'captures nothing when output CO2 equals input CO2' do
        # Fossil input: 50 MJ * 0.0564 kg/MJ = 2.82 kg CO2
        # Biogenic input: 50 MJ * 0.06 kg/MJ = 3.0 kg CO2
        # Output inherits weighted mix: 100 MJ * ((2.82 + 3.0)/100) = 5.82 kg CO2

        # Fossil output: 100 MJ * (2.82/100) = 2.82 kg CO2
        # Fossil captured: (A + B - C) * 0.90 = (2.82 + 0 - 2.82) * 0.90 = 0 kg
        expect(ccs_mixed_plant).to have_query_value(:direct_co2_output_production_capture_fossil, 0.0)

        # Biogenic output: 100 MJ * (3.0/100) = 3.0 kg CO2
        # Biogenic captured: (A - C) * 0.90 = (3.0 - 3.0) * 0.90 = 0 kg
        expect(ccs_mixed_plant).to have_query_value(:direct_co2_output_production_capture_biogenic, 0.0)
      end

      it 'reports zero net emissions (no capture occurs)' do
        # Fossil: A + B - Capture - C = 2.82 + 0 - 0 - 2.82 = 0 kg
        # Biogenic: A - Capture - C = 3.0 - 0 - 3.0 = 0 kg
        # Reporting (fossil only): 0 kg CO2
        expect(ccs_mixed_plant).to have_query_value(:direct_reporting_emissions_co2_production, 0.0)
      end

      it 'fossil production emissions are zero (no capture)' do
        # Fossil: A + B - Capture - C = 2.82 + 0 - 0 - 2.82 = 0 kg
        expect(ccs_mixed_plant).to have_query_value(:direct_co2_output_production_emissions_fossil, 0.0)
      end

      it 'biogenic production emissions are zero (no capture)' do
        # Biogenic: A - Capture - C = 3.0 - 0 - 3.0 = 0 kg
        expect(ccs_mixed_plant).to have_query_value(:direct_co2_output_production_emissions_biogenic, 0.0)
      end

      it 'reporting equals fossil component only' do
        fossil_net = ccs_mixed_plant.query.direct_co2_output_production_emissions_fossil
        reporting = ccs_mixed_plant.query.direct_reporting_emissions_co2_production

        expect(reporting).to be_within(0.0001).of(fossil_net)
        expect(reporting).to be_within(0.0001).of(0.0)
      end
    end

    context 'with biogenic CCS plant (BECCS)' do
      # Create a graph:
      # [Biogenic Waste Producer] -> [BECCS Plant] -> [Terminus]
      # BECCS captures 95% of biogenic CO2 (negative emissions scenario)
      # NOTE: Electricity carrier doesn't set CO2 values, so it inherits from supply mix
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 200)
          builder.add(:beccs_plant, groups: [:emissions], ccs_capture_rate: 0.95)
          builder.add(:biogenic_waste_producer, groups: [:primary_energy_demand])

          builder.connect(:biogenic_waste_producer, :beccs_plant, :biogenic_waste, type: :share)
          builder.connect(:beccs_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:biogenic_waste, potential_co2_conversion_per_mj: 0.06)
          # electricity carrier not set - inherits biogenic CO2 from supply mix
        end
      end

      let(:graph) { builder.to_qernel }
      let(:beccs_plant) { graph.node(:beccs_plant) }

      it 'captures nothing when output equals input' do
        # Biogenic input: 200 MJ * 0.06 kg/MJ = 12.0 kg CO2
        # Biogenic output (inherited): 200 MJ * 0.06 kg/MJ = 12.0 kg CO2
        # Captured: (A - C) * 0.95 = (12.0 - 12.0) * 0.95 = 0 kg
        expect(beccs_plant).to have_query_value(:direct_co2_output_production_capture_biogenic, 0.0)
      end

      it 'has zero fossil capture' do
        expect(beccs_plant).to have_query_value(:direct_co2_output_production_capture_fossil, 0.0)
      end

      it 'reports zero (fossil only, no capture)' do
        # Biogenic: A - Capture - C = 12.0 - 0 - 12.0 = 0 kg CO2
        # Fossil: 0.0 kg CO2
        # Reporting (fossil only): 0 kg CO2
        expect(beccs_plant).to have_query_value(:direct_reporting_emissions_co2_production, 0.0)
      end

      it 'net biogenic production is zero (no capture)' do
        # Biogenic: A - Capture - C = 12.0 - 0 - 12.0 = 0 kg CO2
        expect(beccs_plant).to have_query_value(:direct_co2_output_production_emissions_biogenic, 0.0)
      end
    end

    context 'with fossil-only input (backward compatibility)' do
      # Verify existing behavior still works for fossil-only scenarios
      # Create a graph:
      # [Coal Producer] -> [Coal Plant] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:coal_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_plant) { graph.node(:coal_plant) }

      it 'reports only fossil emissions when biogenic is zero' do
        # Fossil: 100 MJ * 0.09 kg/MJ = 9.0 kg CO2
        # Biogenic: 0 kg CO2
        # Total reporting: 9.0 + 0 = 9.0 kg CO2
        expect(coal_plant).to have_query_value(:direct_reporting_emissions_co2_production, 9.0)
      end

      it 'has non-zero fossil production emissions' do
        expect(coal_plant).to have_query_value(:direct_co2_output_production_emissions_fossil, 9.0)
      end

      it 'has zero biogenic production emissions' do
        expect(coal_plant).to have_query_value(:direct_co2_output_production_emissions_biogenic, 0.0)
      end

      it 'reporting equals fossil component only (backward compatible)' do
        fossil = coal_plant.query.direct_co2_output_production_emissions_fossil
        reporting = coal_plant.query.direct_reporting_emissions_co2_production

        expect(reporting).to eq(fossil)
      end
    end
  end

  describe '#direct_reporting_emissions_total_ghg_emissions' do
    context 'with basic fossil input' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:coal_plant, groups: [:emissions])
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_plant) { graph.node(:coal_plant) }

      it 'equals production - capture + other_ghg when no capture' do
        # Production: A + B - C = 9.0 + 0 - 0 = 9.0 kg
        # Capture: 0 kg
        # Other GHG: 0 kg (placeholder)
        # Total: 9.0 - 0 + 0 = 9.0 kg
        expect(coal_plant).to have_query_value(:direct_reporting_emissions_total_ghg_emissions, 9.0)
      end

      it 'equals production when capture and other_ghg are zero' do
        production = coal_plant.query.direct_reporting_emissions_co2_production
        total = coal_plant.query.direct_reporting_emissions_total_ghg_emissions

        expect(total).to eq(production)
      end
    end

    context 'with zero emissions' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:passthrough, groups: [:emissions])
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :passthrough, :electricity, type: :share)
          builder.connect(:passthrough, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:passthrough) { graph.node(:passthrough) }

      it 'returns zero when all components are zero' do
        expect(passthrough).to have_query_value(:direct_reporting_emissions_total_ghg_emissions, 0.0)
      end
    end

    context 'with node not in emissions group' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:non_emissions_node)
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :non_emissions_node, :electricity, type: :share)
          builder.connect(:non_emissions_node, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:electricity, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:non_emissions_node) { graph.node(:non_emissions_node) }

      it 'returns nil for nodes not in emissions group' do
        expect(non_emissions_node.query.direct_reporting_emissions_total_ghg_emissions).to be_nil
      end
    end
  end

  describe '#ghg_carrier' do
    context 'with a co2 input slot' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:co2_node, groups: [:emissions])
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :co2_node, :co2, type: :share)
          builder.connect(:co2_node, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:co2, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:co2_node) { graph.node(:co2_node) }

      it 'returns CO2' do
        expect(co2_node.query.ghg_carrier).to eq('CO2')
      end
    end

    context 'with an other_ghg input slot' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:ghg_node, groups: [:emissions])
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :ghg_node, :other_ghg, type: :share)
          builder.connect(:ghg_node, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:other_ghg, co2_conversion_per_mj: 0.0)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:ghg_node) { graph.node(:ghg_node) }

      it 'returns Other GHG' do
        expect(ghg_node.query.ghg_carrier).to eq('Other GHG')
      end
    end
  end
end
