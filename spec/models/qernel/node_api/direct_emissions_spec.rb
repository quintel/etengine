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

  pending 'gross, captured, and net fossil emissions' do
    context 'with CCS plant capturing 85% of emissions' do
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

      it 'calculates gross emissions (before capture)' do
        # 100 MJ * 0.0564 kg/MJ = 5.64 kg CO2
        expect(ccs_plant).to have_query_value(:direct_co2_output_production_emissions_fossil, 5.64)
      end

      it 'calculates captured emissions' do
        # 5.64 * 0.85 = 4.794 kg CO2 captured
        expect(ccs_plant).to have_query_value(:direct_co2_input_content_carriers_fossil_captured, 4.794)
      end

      it 'calculates net emissions (after capture)' do
        # 5.64 * (1 - 0.85) = 0.846 kg CO2
        expect(ccs_plant).to have_query_value(:direct_co2_input_content_carriers_fossil, 0.846)
      end

      it 'validates net = gross - captured' do
        gross = ccs_plant.query.direct_co2_output_production_emissions_fossil
        captured = ccs_plant.query.direct_co2_input_content_carriers_fossil_captured
        net = ccs_plant.query.direct_co2_input_content_carriers_fossil

        expect(net).to be_within(0.001).of(gross - captured)
      end
    end

    context 'with no CCS (free_co2_factor = 0)' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 200)
          builder.add(:coal_plant, groups: [:emissions], free_co2_factor: 0.0)
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_plant) { graph.node(:coal_plant) }

      it 'has zero captured emissions' do
        expect(coal_plant).to have_query_value(:direct_co2_input_content_carriers_fossil_captured, 0.0)
      end

      it 'has gross = net (no capture)' do
        gross = coal_plant.query.direct_co2_output_production_emissions_fossil
        net = coal_plant.query.direct_co2_input_content_carriers_fossil

        expect(net).to eq(gross)
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
    end
  end
end
