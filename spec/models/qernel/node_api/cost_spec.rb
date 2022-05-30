# frozen_string_literal: true

require 'spec_helper'

describe 'Qernel::NodeApi cost calculations' do
  let(:node) { FactoryBot.build(:node) }
  let(:api) { node.node_api }

  def build_slot(node, carrier, direction, conversion = 1.0)
    Qernel::Slot.new(
      1, node, Qernel::Carrier.new(key: carrier), direction
    ).with(conversion: conversion)
  end

  describe '#input_capacity' do
    # e-eff  h-eff  e-cap  h-cap  expected outcome
    #  0.4    nil    800    nil     2000
    #  0.4    0.1    800    400     error   error in data
    #  nil    0.1    nil    400     4000
    #  nil    nil    800    400     error   incomplete data
    #  nil    0.1    800    nil     error   incomplete data
    #  0.4    nil    nil    400     error   incomplete data
    #  0.4    0.2    nil    nil     error   incomplete data
    #  0.4    0.2    nil    nil     error   incomplete data
    #    0    0     800       0     error   incomplete data

    it 'calculates correctly when only electrical capacity and electrical ' \
        'efficiency are given' do
      node.with(
        electricity_output_conversion: 0.4,
        electricity_output_capacity: 800
      )

      expect(node.node_api.input_capacity).to eq(2000)
    end

    it 'calculates correctly when only heat capacity and heat efficiency ' \
        'are given' do
      node.with(heat_output_conversion: 0.1, heat_output_capacity: 400)
      expect(node.node_api.input_capacity).to eq(4000)
    end

    it 'returns zero when capacity and conversion are both zero' do
      node.with(
        electricity_output_capacity: 0,
        electricity_output_conversion: 0
      )

      expect(node.node_api.input_capacity).to eq(0)
    end

    it 'returns zero when heat capacity and conversion are both zero' do
      node.with(
        heat_output_capacity: 0,
        heat_and_cold_output_conversion: 0
      )

      expect(node.node_api.input_capacity).to eq(0)
    end
  end

  describe '#total_cost' do
    it 'calculates correctly when values are given' do
      node.with(fixed_costs: 100, variable_costs: 200)
      expect(node.node_api.send(:total_costs)).to eq(300)
    end

    it 'returns nil when variable costs is nil' do
      node.with(fixed_costs: 100, variable_costs: nil)
      expect(node.node_api.send(:total_costs)).to eq(nil)
    end

    it 'returns nil when fixed costs is nil' do
      node.with(fixed_costs: nil, variable_costs: 200)
      expect(node.node_api.send(:total_costs)).to eq(nil)
    end
  end

  describe '#fixed_costs' do
    it 'calculates correctly when values are given' do
      node.with(
        cost_of_capital: 100,
        depreciation_costs: 200,
        fixed_operation_and_maintenance_costs_per_year: 300
      )

      expect(node.node_api.send(:fixed_costs)).to eq(600)
    end

    it 'adds correctly when cost_of_capital is nil' do
      node.with(
        cost_of_capital: nil,
        depreciation_costs: 200,
        fixed_operation_and_maintenance_costs_per_year: 300
      )

      expect(node.node_api.send(:fixed_costs)).to eq(500)
    end

    it 'adds correctly when depreciation costs are nil' do
      node.with(
        cost_of_capital: 100,
        depreciation_costs: nil,
        fixed_operation_and_maintenance_costs_per_year: 300
      )

      expect(node.node_api.send(:fixed_costs)).to eq(400)
    end

    it 'adds correctly when fixed O&M costs are nil' do
      node.with(
        cost_of_capital: 100,
        depreciation_costs: 200,
        fixed_operation_and_maintenance_costs_per_year: nil
      )

      expect(node.node_api.send(:fixed_costs)).to eq(300)
    end
  end

  describe '#cost_of_capital' do
    let(:attrs) do
      {
        average_investment: 100.0,
        wacc: 0.1,
        construction_time: 1.0,
        technical_lifetime: 10.0
      }
    end

    it 'calculates when all values are given' do
      node.with(
        average_investment: 100,
        wacc: 0.1,
        construction_time: 1,
        technical_lifetime: 10
      )

      expect(node.node_api.send(:cost_of_capital)).to eq(11)
    end

    it 'raises error when technical life time is zero' do
      node.with(attrs.merge(technical_lifetime: 0.0))

      expect { api.send(:cost_of_capital) }
        .to raise_error(Qernel::IllegalZeroError)
    end
  end

  describe '#depreciation_costs' do
    let(:attrs) do
      { total_investment_over_lifetime: 100.0, technical_lifetime: 10.0 }
    end

    it 'calculates when everything is set' do
      node.with(attrs)
      expect(api.send(:depreciation_costs)).to eq(10)
    end

    it 'raises error when total_investment_costs < 0' do
      node.with(attrs.merge(total_investment_over_lifetime: -1.0))

      expect { api.send(:depreciation_costs) }
        .to raise_error(Qernel::IllegalValueError)
    end

    it 'does not raise error when total_investment_costs is zero' do
      node.with(attrs.merge(total_investment_over_lifetime: 0.0))

      expect(api.send(:depreciation_costs)).to be_zero
    end

    it 'raises error when total_investment_costs is nil' do
      node.with(attrs.merge(total_investment_over_lifetime: nil))

      expect { api.send(:depreciation_costs) }.to raise_error(NoMethodError)
    end

    it 'raises error when technical_lifetime is 0' do
      node.with(attrs.merge(technical_lifetime: 0))

      expect { api.send(:depreciation_costs) }
        .to raise_error(Qernel::IllegalValueError)
    end

    it 'raises error when technical_lifetime is nil' do
      node.with(attrs.merge(technical_lifetime: nil))
      expect { api.send(:depreciation_costs) }.to raise_error(NoMethodError)
    end
  end

  describe '#marginal_costs' do
    it 'calculates correctly when values are given' do
      node.with(
        variable_costs_per_typical_input: 200,
        variable_costs_per_typical_input_except_waste: 100,
        electricity_output_conversion: 0.5
      )

      node.add_slot(
        Qernel::Slot.factory(
          nil, 1, node, Qernel::Carrier.new(key: :electricity), :output
        )
      )

      expect(node.node_api.send(:marginal_costs)).to eq(720_000.0)
    end
  end

  describe '#marginal_heat_costs' do
    it 'calculates correctly when values are given' do
      node.with(
        variable_costs_per_typical_input: 200,
        variable_costs_per_typical_input_except_waste: 100,
        heat_output_conversion: 0.5
      )

      expect(node.node_api.send(:marginal_heat_costs))
        .to eq(720_000.0)
    end
  end

  describe '#variable_costs' do
    it 'calculates correctly when values are given' do
      node.with(variable_costs_per_typical_input: 300, typical_input: 2)
      expect(node.node_api.send(:variable_costs)).to eq(600)
    end
  end

  describe '#variable_costs_per_typical_input' do
    let(:attrs) do
      {
        weighted_carrier_cost_per_mj: 200,
        co2_emissions_costs_per_typical_input: 300,
        variable_operation_and_maintenance_costs_per_typical_input: 400
      }
    end

    it 'calculates correctly when values are given' do
      node.with(attrs)

      expect(
        node.node_api.send(:variable_costs_per_typical_input)
      ).to eq(900)
    end

    context 'with heat and electricity outputs' do
      before do
        node.add_slot(build_slot(node, :heat, :output, 0.4))
        node.add_slot(build_slot(node, :electricity, :output, 0.6))
        node.with(attrs.merge(waste_outputs: [:heat]))
      end

      it 'defaults to including waste outputs' do
        expect(api.send(:variable_costs_per_typical_input)).to eq(900)
      end

      it 'ignores waste outputs when include_waste: false' do
        expect(
          api.send(:variable_costs_per_typical_input, include_waste: false)
        ).to eq(700)
      end
    end

    context 'with heat, electricity, and loss outputs' do
      before do
        node.add_slot(build_slot(node, :heat, :output, 0.3))
        node.add_slot(build_slot(node, :electricity, :output, 0.5))
        node.add_slot(build_slot(node, :loss, :output, 0.2))

        node.with(attrs.merge(waste_outputs: [:heat]))
      end

      it 'defaults to including waste and loss outputs' do
        expect(api.send(:variable_costs_per_typical_input)).to eq(900)
      end

      it 'includes a costable share of loss when include_waste: false' do
        # 2 from the electricity, plus the electricity share of the loss.
        # loss is 0.2, and electricity is responsible for 0.625 (0.5 / 0.8) of
        # that = 0.5.

        # 400 from the variable operation costs
        # 500 from the carrier and CO2 costs becomes 250 from electricity and
        # 62.5 from loss (electricity is responsible for 0.625 of the loss
        # (0.5 / 0.8))
        expect(
          api.send(:variable_costs_per_typical_input, include_waste: false)
        ).to eq(400 + 250 + 62.5)
      end
    end
  end

  describe '#fuel_costs' do
    let(:attrs) do
      {
        typical_input: 100,
        weighted_carrier_cost_per_mj: 10
      }
    end

    it 'calculates when everything is set' do
      node.with(attrs)
      expect(api.send(:fuel_costs)).to eq(1000)
    end

    it 'returns 0 when typical_input <= 0' do
      node.with(attrs.merge(typical_input: -1.0))
      expect { api.send(:fuel_costs) }
        .to raise_error(Qernel::IllegalNegativeError)
    end

    it 'raises error when typical_input is nil' do
      node.with(attrs.merge(typical_input: nil))
      expect { api.send(:fuel_costs) }.to raise_error(NoMethodError)
    end
  end

  describe '#co2_emissions_costs' do
    it 'calculates when everything is set' do
      node.with(
        typical_input: 500,
        co2_emissions_costs_per_typical_input: 2
      )

      expect(node.node_api.send(:co2_emissions_costs)).to eq(1000)
    end
  end

  describe '#co2_emissions_costs_per_typical_input' do
    let(:attrs) do
      {
        weighted_carrier_co2_per_mj: 2.0,
        takes_part_in_ets: 1.0,
        free_co2_factor: 0.0
      }
    end

    before do
      node.with(attrs)

      allow(api).to receive(:area).and_return(
        double(co2_price: 2.0, co2_percentage_free: 0.0)
      )
    end

    describe '#co2_emissions_costs_per_typical_input' do
      let(:attrs) do
        {
          weighted_carrier_co2_per_mj: 2.0,
          takes_part_in_ets: 1.0,
          free_co2_factor: 0.0
        }
      end

      before do
        node.with(attrs)

        allow(api).to receive(:area).and_return(
          double(co2_price: 2.0, co2_percentage_free: 0.0)
        )
      end

      it 'calculates when everything is set' do
        expect(api.send(:co2_emissions_costs_per_typical_input)).to eq(4.0)
      end
    end
  end

  describe '#variable_operation_and_maintenance_costs' do
    it 'calculates when everything is set' do
      node.with(
        variable_operation_and_maintenance_costs_per_typical_input: 500,
        typical_input: 2
      )

      expect(node.node_api.send(
        :variable_operation_and_maintenance_costs
      )).to eq(1000)
    end
  end

  describe '#variable_operation_and_maintenance_costs_per_typical_input' do
    it 'calculates when everything is set' do
      node.with(
        variable_operation_and_maintenance_costs_per_full_load_hour: 500,
        variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour: 400,
        input_capacity: 2
      )

      expect(node.node_api.send(
        :variable_operation_and_maintenance_costs_per_typical_input
      )).to eq(0.125)
    end
  end

  describe '#total_initial_investment' do
    it 'returns nil when values are not set' do
      node.with(
        initial_investment: nil,
        ccs_investment: nil,
        cost_of_installing: nil,
        storage_costs: 0.0
      )

      expect(node.node_api.total_initial_investment).to be_nil
    end

    it 'returns initial_investment when only it is set' do
      node.with(initial_investment: 10.0)
      expect(node.node_api.total_initial_investment).to eq(10)
    end

    it 'returns ccs_investment when only it is set' do
      node.with(ccs_investment: 11.0)
      expect(node.node_api.total_initial_investment).to eq(11)
    end

    it 'returns cost_of_installing when only it is set' do
      node.with(cost_of_installing: 12.0)
      expect(node.node_api.total_initial_investment).to eq(12)
    end

    it 'returns storage_costs when only it is set' do
      node.with(storage_costs: 13.0)
      expect(node.node_api.total_initial_investment).to eq(13)
    end

    it 'calculates when everything is set' do
      node.with(
        initial_investment: 500,
        ccs_investment: 100,
        cost_of_installing: 66
      )

      expect(node.node_api.total_initial_investment).to eq(666)
    end

    it 'includes storage when present' do
      node.with(
        initial_investment: 500,
        ccs_investment: 100,
        cost_of_installing: 66,
        storage_costs: 10
      )

      expect(node.node_api.total_initial_investment).to eq(676)
    end
  end

  describe '#total_investment_over_lifetime' do
    it 'calculates when everything is set' do
      node.with(
        total_initial_investment: 10_000,
        decommissioning_costs: 5000
      )

      expect(
        node.node_api.total_investment_over_lifetime
      ).to eq(15_000)
    end
  end

  describe '#storage_costs' do
    let(:storage) do
      Atlas::NodeAttributes::Storage.new(volume: volume, cost_per_mwh: cost)
    end

    before { node.with(storage: storage) }

    context 'when the node has no storage' do
      let(:storage) { nil }

      it 'is zero' do
        expect(node.node_api.storage_costs).to eq(0)
      end
    end

    context 'with cost_per_mwh=10' do
      let(:cost) { 10.0 }

      context 'when volume=0' do
        let(:volume) { 0.0 }

        it 'is zero' do
          expect(node.node_api.storage_costs).to eq(0)
        end
      end

      context 'when volume=10' do
        let(:volume) { 10.0 }

        it 'is 100' do
          expect(node.node_api.storage_costs).to eq(100)
        end
      end
    end

    context 'with cost_per_mwh = nil' do
      let(:cost) { nil }

      context 'when volume=0' do
        let(:volume) { 0.0 }

        it 'is zero' do
          expect(node.node_api.storage_costs).to eq(0)
        end
      end

      context 'when volume=10' do
        let(:volume) { 10.0 }

        it 'is zero' do
          expect(node.node_api.storage_costs).to eq(0)
        end
      end
    end
  end

  describe '#capital_expenditures_ccs' do
    let(:ccs_investment) { 10.0 }
    let(:technical_lifetime) { 1.0 }
    let(:wacc) { 0.0 }

    before do
      node.with(
        ccs_investment: ccs_investment,
        construction_time: 0,
        technical_lifetime: technical_lifetime,
        wacc: wacc
      )
    end

    it 'equals investment when expenditure factor is 1.0' do
      expect(node.node_api.capital_expenditures_ccs).to eq(ccs_investment)
    end

    context 'when wacc=1.0 (expenditure factor = 1.5)' do
      let(:wacc) { 1.0 }

      it 'equals 1.5 times the investment' do
        expect(node.node_api.capital_expenditures_ccs).to eq(ccs_investment * 1.5)
      end
    end

    context 'when plant lifetime doubles (expenditure factor = 0.5)' do
      let(:technical_lifetime) { 2.0 }

      it 'equals half the investment' do
        expect(node.node_api.capital_expenditures_ccs).to eq(ccs_investment / 2)
      end
    end

    context 'with no ccs_investment' do
      let(:ccs_investment) { nil }

      it 'is zero' do
        expect(node.node_api.capital_expenditures_ccs).to eq(0)
      end
    end
  end

  describe '#capital_expenditures_excluding_ccs' do
    let(:basic_investment) { 10.0 }
    let(:ccs_investment) { 10.0 }
    let(:technical_lifetime) { 1.0 }
    let(:wacc) { 0.0 }

    before do
      node.with(
        ccs_investment: ccs_investment,
        initial_investment: basic_investment,
        cost_of_installing: basic_investment,
        storage_costs: basic_investment,
        decommissioning_costs: basic_investment,
        construction_time: 0,
        technical_lifetime: technical_lifetime,
        wacc: wacc
      )
    end

    it 'equals investment when expenditure factor is 1.0' do
      expect(node.node_api.capital_expenditures_excluding_ccs).to eq(4 * basic_investment)
    end

    context 'when wacc=1.0 (expenditure factor = 1.5)' do
      let(:wacc) { 1.0 }

      it 'equals twice the investment' do
        expect(node.node_api.capital_expenditures_excluding_ccs).to eq(6 * basic_investment)
      end
    end

    context 'when plant lifetime doubles (expenditure factor = 0.5)' do
      let(:technical_lifetime) { 2.0 }

      it 'equals half the investment' do
        expect(node.node_api.capital_expenditures_excluding_ccs).to eq(2 * basic_investment)
      end
    end

    context 'with no ccs_investment' do
      let(:ccs_investment) { nil }

      it 'makes no difference' do
        expect(node.node_api.capital_expenditures_excluding_ccs).to eq(4 * basic_investment)
      end
    end
  end

  describe '#operating_expenses_ccs' do
    before do
      node.with(
        co2_emissions_costs: 1.5,
        variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour: 3600.0,
        input_capacity: 10.0,
        typical_input: 5.0
      )
    end

    it 'calculates when everything is set' do
      expect(node.node_api.operating_expenses_ccs).to eq(2)
    end
  end

  describe '#operating_expenses_excluding_ccs' do
    before do
      node.with(
        fixed_operation_and_maintenance_costs_per_year: 1.5,
        variable_operation_and_maintenance_costs_per_full_load_hour: 3600.0,
        variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour: 3600.0,
        input_capacity: 10.0,
        typical_input: 5.0
      )
    end

    it 'calculates when everything is set' do
      expect(node.node_api.operating_expenses_excluding_ccs).to eq(2)
    end
  end
end
