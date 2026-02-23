# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::DirectEmissions do
  describe '#direct_co2_emission_of_fossil' do
    context 'with a pure fossil carrier (coal)' do
      # Create a simple graph:
      # [Coal Producer] -> [Power Plant] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:power_plant)
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
        expect(power_plant).to have_query_value(:direct_co2_emission_of_fossil, 9.0)
      end
    end

    context 'with a pure fossil carrier (natural gas)' do
      # Create a simple graph:
      # [Gas Producer] -> [Gas Plant] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 200)
          builder.add(:gas_plant)
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
        expect(gas_plant).to have_query_value(:direct_co2_emission_of_fossil, 11.28)
      end
    end

    context 'with secondary carriers (electricity)' do
      # Create a graph:
      # [Coal Producer] -> [Power Plant] -> [Electric Heater] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:electric_heater)
          builder.add(:power_plant)
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
        expect(electric_heater).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end

      it 'shows emissions at the power plant' do
        # 50 MJ * 0.09 kg/MJ = 4.5 kg CO2
        expect(power_plant).to have_query_value(:direct_co2_emission_of_fossil, 4.5)
      end
    end

    context 'with CCS capture (free_co2_factor)' do
      # Create a graph:
      # [Gas Producer] -> [CCS Plant] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:ccs_plant, free_co2_factor: 0.85)
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
        expect(ccs_plant).to have_query_value(:direct_co2_emission_of_fossil, 0.846)
      end
    end


    context 'with multi-level supply chain' do
      # Create a graph:
      # [Coal Producer] -> [Coal Plant] -> [Electricity Grid] -> [Data Center] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:data_center)
          builder.add(:electricity_grid)
          builder.add(:coal_plant)
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
        expect(coal_plant).to have_query_value(:direct_co2_emission_of_fossil, 4.5)
      end

      it 'shows zero emissions at electricity grid' do
        # Electricity has no carbon content
        expect(electricity_grid).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end

      it 'shows zero emissions at data center' do
        # Electricity has no carbon content
        expect(data_center).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end
    end

    context 'with crude oil' do
      # Create a graph:
      # [Oil Extraction] -> [Refinery] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:refinery)
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
        expect(refinery).to have_query_value(:direct_co2_emission_of_fossil, 7.33)
      end
    end

    context 'with no demand' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 0)
          builder.add(:power_plant)
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :power_plant, :coal, type: :share)
          builder.connect(:power_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:power_plant) { graph.node(:power_plant) }

      it 'returns zero when demand is zero' do
        expect(power_plant).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end
    end

    context 'with carrier having no CO2 value' do
      # Some carriers may not have CO2 values defined
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:consumer)
          builder.add(:producer, groups: [:primary_energy_demand])

          builder.connect(:producer, :consumer, :custom_carrier, type: :share)
          builder.connect(:consumer, :terminus, :electricity, type: :share)

          # custom_carrier has no co2_conversion_per_mj set
        end
      end

      let(:graph) { builder.to_qernel }
      let(:consumer) { graph.node(:consumer) }

      it 'returns zero when carrier has no CO2 value' do
        expect(consumer).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end
    end
  end

  describe 'gross, captured, and net fossil emissions' do
    context 'with CCS plant capturing 85% of emissions' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:ccs_plant, free_co2_factor: 0.85)
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
        expect(ccs_plant).to have_query_value(:direct_co2_emission_of_fossil_gross, 5.64)
      end

      it 'calculates captured emissions' do
        # 5.64 * 0.85 = 4.794 kg CO2 captured
        expect(ccs_plant).to have_query_value(:direct_co2_emission_of_fossil_captured, 4.794)
      end

      it 'calculates net emissions (after capture)' do
        # 5.64 * (1 - 0.85) = 0.846 kg CO2
        expect(ccs_plant).to have_query_value(:direct_co2_emission_of_fossil, 0.846)
      end

      it 'validates net = gross - captured' do
        gross = ccs_plant.query.direct_co2_emission_of_fossil_gross
        captured = ccs_plant.query.direct_co2_emission_of_fossil_captured
        net = ccs_plant.query.direct_co2_emission_of_fossil

        expect(net).to be_within(0.001).of(gross - captured)
      end
    end

    context 'with no CCS (free_co2_factor = 0)' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 200)
          builder.add(:coal_plant, free_co2_factor: 0.0)
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_plant) { graph.node(:coal_plant) }

      it 'has zero captured emissions' do
        expect(coal_plant).to have_query_value(:direct_co2_emission_of_fossil_captured, 0.0)
      end

      it 'has gross = net (no capture)' do
        gross = coal_plant.query.direct_co2_emission_of_fossil_gross
        net = coal_plant.query.direct_co2_emission_of_fossil

        expect(net).to eq(gross)
      end
    end
  end

  describe '#direct_output_co2_composition' do
    context 'with a node outputting a carrier with defined CO2 value' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 100)
          builder.add(:coal_plant)
          builder.add(:coal_producer, groups: [:primary_energy_demand])

          builder.connect(:coal_producer, :coal_plant, :coal, type: :share)
          builder.connect(:coal_plant, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:coal_producer) { graph.node(:coal_producer) }

      it 'returns the carrier CO2 value' do
        expect(coal_producer.query.direct_output_co2_composition).to eq(0.09)
      end
    end


    context 'with zero total input' do
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 0)
          builder.add(:mixer)
          builder.add(:source, groups: [:primary_energy_demand])

          builder.connect(:source, :mixer, :coal, type: :share)
          builder.connect(:mixer, :terminus, :electricity, type: :share)

          builder.carrier_attrs(:coal, co2_conversion_per_mj: 0.09)
        end
      end

      let(:graph) { builder.to_qernel }
      let(:mixer) { graph.node(:mixer) }

      it 'returns nil when total input is zero' do
        expect(mixer.query.direct_output_co2_composition).to be_nil
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
          builder.add(:gas_burner)
          builder.add(:network_gas_distributor)
          builder.add(:natural_gas_producer, groups: [:primary_energy_demand], demand: 70)
          builder.add(:green_gas_producer, groups: [:primary_energy_demand], demand: 30)

          # Network gas distributor receives from two sources
          builder.connect(:natural_gas_producer, :network_gas_distributor, :natural_gas, type: :share)
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

      it 'calculates weighted average composition for network gas' do
        # Weighted average: (70 * 0.0564 + 30 * 0.0) / 100 = 0.03948 kg CO2/MJ
        expect(distributor.query.direct_output_co2_composition).to be_within(0.00001).of(0.03948)
      end

      it 'uses the mixed composition for downstream emissions calculation' do
        # Gas burner receives 100 MJ network gas with 0.03948 kg/MJ composition
        # Total emissions: 100 * 0.03948 = 3.948 kg CO2
        expect(gas_burner).to have_query_value(:direct_co2_emission_of_fossil, 3.948)
      end

      it 'tracks composition through the supply chain recursively' do
        # Verify the recursion: burner gets composition from distributor (via edge)
        burner_input_edge = gas_burner.inputs.first.edges.first
        composition = burner_input_edge.query.direct_output_co2_composition

        expect(composition).to be_within(0.00001).of(0.03948)
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
          builder.add(:electric_heater)
          builder.add(:coal_plant)
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
        expect(coal_plant).to have_query_value(:direct_co2_emission_of_fossil, 9.0)
      end

      it 'shows zero direct emissions at electric heater (no combustion)' do
        # Electricity is secondary carrier - consumer does not combust anything
        expect(electric_heater).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end
    end

    context 'with steam_hot_water from gas CHP' do
      # Create a graph:
      # [Gas Producer] -> [Gas CHP] -> [Steam Consumer] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 50)
          builder.add(:steam_consumer)
          builder.add(:gas_chp)
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
        expect(gas_chp).to have_query_value(:direct_co2_emission_of_fossil, 2.82)
      end

      it 'shows zero direct emissions at steam consumer (no combustion)' do
        # Steam is secondary carrier - consumer does not combust anything
        expect(steam_consumer).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end
    end

    context 'with hot_water from boiler' do
      # Create a graph:
      # [Coal Producer] -> [Boiler] -> [Hot Water Heater] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 75)
          builder.add(:hot_water_heater)
          builder.add(:boiler)
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
        expect(boiler).to have_query_value(:direct_co2_emission_of_fossil, 6.75)
      end

      it 'shows zero direct emissions at hot water heater (no combustion)' do
        # Hot water is secondary carrier - consumer does not combust anything
        expect(hot_water_heater).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end
    end

    context 'with imported_electricity' do
      # Create a graph:
      # [Electricity Import] -> [Data Center] -> [Terminus]
      let(:builder) do
        TestGraphBuilder.new.tap do |builder|
          builder.add(:terminus, demand: 200)
          builder.add(:data_center)
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
        expect(data_center).to have_query_value(:direct_co2_emission_of_fossil, 0.0)
      end
    end
  end
end
