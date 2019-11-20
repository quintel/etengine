require 'spec_helper'

module Qernel

  describe Qernel::ConverterApi, 'cost calculations' do

    before :each do
      @c   = Qernel::Converter.new(id:1)
      @api = @c.converter_api
    end

    describe '#input_capacity' do
      #
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
      #

      it "should calculate correctly when only electrical capacity and electrical efficiency are given" do
        @c.with electricity_output_conversion: 0.4, electricity_output_capacity: 800
        expect(@c.converter_api.input_capacity).to eq(2000)
      end

      it "should calculate correctly when only heat capacity and heat efficiency are given" do
        @c.with heat_output_conversion: 0.1, heat_output_capacity: 400
        expect(@c.converter_api.input_capacity).to eq(4000)
      end

      it "should return zero when capacity and conversion are both zero" do
        @c.with electricity_output_capacity: 0, electricity_output_conversion: 0
        expect(@c.converter_api.input_capacity).to eq(0)
        @c.with heat_output_capacity: 0, heat_and_cold_output_conversion: 0
        expect(@c.converter_api.input_capacity).to eq(0)
      end

      it "should raise error when incomplete" do
        @c.with electricity_output_conversion: 0.4,
                electricity_output_capacity: nil,
                heat_and_cold_output_conversion: nil,
                heat_output_capacity: 400

        expect { @c.converter_api.input_capacity }.to raise_error(NoMethodError)
      end
    end

    describe '#total_cost' do
      it "should calculate correctly when values are given" do
        @c.with fixed_costs: 100, variable_costs: 200
        expect(@c.converter_api.send(:total_costs)).to eq(300)
      end

      it "should return nil when one of the two is missing" do
        @c.with fixed_costs: 100, variable_costs: nil
        expect(@c.converter_api.send(:total_costs)).to eq(nil)
        @c.with fixed_costs: nil, variable_costs: 200
        expect(@c.converter_api.send(:total_costs)).to eq(nil)
      end
    end

    describe '#fixed_costs' do

      it "should calculate correctly when values are given" do
        @c.with cost_of_capital: 100, depreciation_costs: 200, fixed_operation_and_maintenance_costs_per_year: 300
        expect(@c.converter_api.send(:fixed_costs)).to eq(600)
      end

      it "should add correctly when cost_of_capital is nil" do
        @c.with cost_of_capital: nil, depreciation_costs: 200, fixed_operation_and_maintenance_costs_per_year: 300
        expect(@c.converter_api.send(:fixed_costs)).to eq(500)
      end

      it "should add correctly when depreciation costs are nil" do
        @c.with cost_of_capital: 100, depreciation_costs: nil, fixed_operation_and_maintenance_costs_per_year: 300
        expect(@c.converter_api.send(:fixed_costs)).to eq(400)
      end

      it "should add correctly when fixed O&M costs are nil" do
        @c.with cost_of_capital: 100, depreciation_costs: 200, fixed_operation_and_maintenance_costs_per_year: nil
        expect(@c.converter_api.send(:fixed_costs)).to eq(300)
      end

    end

    describe '#cost_of_capital' do
      let(:attrs) { {
        average_investment: 100.0,
        wacc:                 0.1,
        construction_time:    1.0,
        technical_lifetime:  10.0,
      } }

      it "should calculate when all values are given" do
        @c.with average_investment: 100, wacc: 0.1, construction_time: 1, technical_lifetime: 10
        expect(@c.converter_api.send(:cost_of_capital)).to eq(11)
      end

      it "should raise error when technical life time is zero" do
        @c.with(attrs.merge(technical_lifetime: 0.0))

        expect { @api.send(:cost_of_capital) }.
          to raise_error(Qernel::IllegalZeroError)
      end
    end

    describe '#depreciation_costs' do
      let(:attrs) { {
        total_investment_over_lifetime: 100.0,
        technical_lifetime:              10.0
      } }

      it "should calculate when everything is set" do
        @c.with(attrs)
        expect(@api.send(:depreciation_costs)).to eq(10)
      end

      it "should raise error when total_investment_costs < 0" do
        @c.with(attrs.merge(total_investment_over_lifetime: -1.0))

        expect { @api.send(:depreciation_costs) }
          .to raise_error(Qernel::IllegalValueError)
      end

      it "should not raise error when total_investment_costs is zero" do
        @c.with(attrs.merge(total_investment_over_lifetime: 0.0))

        expect(@api.send(:depreciation_costs)).to be_zero
      end

      it "should raise error when total_investment_costs is nil" do
        @c.with(attrs.merge(total_investment_over_lifetime: nil))

        expect { @api.send(:depreciation_costs) }.to raise_error(NoMethodError)
      end

      it "should raise error when technical_lifetime is 0" do
        @c.with(attrs.merge(technical_lifetime: 0))

        expect { @api.send(:depreciation_costs) }
          .to raise_error(Qernel::IllegalValueError)
      end

      it "should raise error when technical_lifetime is nil" do
        @c.with(attrs.merge(technical_lifetime: nil))
        expect { @api.send(:depreciation_costs) }.to raise_error(NoMethodError)
      end
    end

    describe '#marginal_costs' do
      it "should calculate correctly when values are given" do
        @c.with variable_costs_per_typical_input: 100, electricity_output_conversion: 0.5
        expect(@c.converter_api.send(:marginal_costs)).to eq(720000.0)
      end
    end

    describe '#marginal_heat_costs' do
      it "should calculate correctly when values are given" do
        @c.with variable_costs_per_typical_input: 100, heat_output_conversion: 0.5
        expect(@c.converter_api.send(:marginal_heat_costs)).to eq(720000.0)
      end
    end

    describe '#variable_costs' do
      it "should calculate correctly when values are given" do
        @c.with variable_costs_per_typical_input: 300, typical_input: 2
        expect(@c.converter_api.send(:variable_costs)).to eq(600)
      end
    end

    describe '#variable_costs_per_typical_input' do
      it "should calculate correctly when values are given" do
        @c.with weighted_carrier_cost_per_mj: 200, co2_emissions_costs_per_typical_input: 300,
        variable_operation_and_maintenance_costs_per_typical_input: 400
        expect(@c.converter_api.send(:variable_costs_per_typical_input)).to eq(900)
      end
    end

    describe "#fuel_costs" do
      let(:attrs) { {
        typical_input: 100,
        weighted_carrier_cost_per_mj: 10
      } }

      it "should calculate when everything is set" do
        @c.with(attrs)
        expect(@api.send(:fuel_costs)).to eq(1000)
      end

      it "should return 0 when typical_input <= 0" do
        @c.with(attrs.merge(typical_input: -1.0))
        expect { @api.send(:fuel_costs) }.
          to raise_error(Qernel::IllegalNegativeError)
      end

      it "should raise error when typical_input is nil" do
        @c.with(attrs.merge(typical_input: nil))
        expect { @api.send(:fuel_costs) }.to raise_error(NoMethodError)
      end
    end

    describe '#co2_emissions_costs' do
      it "should calculate when everything is set" do
        @c.with typical_input: 500, co2_emissions_costs_per_typical_input: 2
        expect(@c.converter_api.send(:co2_emissions_costs)).to eq(1000)
      end
    end

    describe '#co2_emissions_costs_per_typical_input' do
      it "should calculate when everything is set" do
        @c.with(
          weighted_carrier_co2_per_mj: 2.0,
          takes_part_in_ets: 1.0,
          free_co2_factor: 0.0
        )

        allow(@api).to receive(:area).and_return(
          double(co2_price: 2.0, co2_percentage_free: 0.0))

        expect(@c.converter_api.send(:co2_emissions_costs_per_typical_input)).to eq(4.0)
      end
    end

    describe '#variable_operation_and_maintenance_costs' do
      it "should calculate when everything is set" do
        @c.with variable_operation_and_maintenance_costs_per_typical_input: 500, typical_input: 2
        expect(@c.converter_api.send(:variable_operation_and_maintenance_costs)).to eq(1000)
      end
    end

    describe '#variable_operation_and_maintenance_costs_per_typical_input' do
      it "should calculate when everything is set" do
        @c.with variable_operation_and_maintenance_costs_per_full_load_hour: 500,
        variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour: 400,
        input_capacity: 2
        expect(@c.converter_api.send(:variable_operation_and_maintenance_costs_per_typical_input)).to eq(0.125)
      end
    end

    describe '#total_initial_investment' do
      it "should calculate when everything is set" do
        @c.with initial_investment: 500, ccs_investment: 100, cost_of_installing: 66
        expect(@c.converter_api.total_initial_investment).to eq(666)
      end

      it "includes storage when present" do
        @c.with initial_investment: 500, ccs_investment: 100, cost_of_installing: 66, storage_costs: 10
        expect(@c.converter_api.total_initial_investment).to eq(676)
      end
    end

    describe '#total_investment_over_lifetime' do
      it "should calculate when everything is set" do
        @c.with total_initial_investment: 10000, decommissioning_costs: 5000
        expect(@c.converter_api.total_investment_over_lifetime).to eq(15000)
      end
    end

    describe "#storage_costs" do
      let(:storage) do
        Atlas::NodeAttributes::Storage.new(volume: volume, cost_per_mwh: cost)
      end

      before { @c.with(storage: storage) }

      context 'when the converter has no storage' do
        let(:storage) { nil }

        it 'is zero' do
          expect(@c.converter_api.storage_costs).to eq(0)
        end
      end

      context 'with cost_per_mwh=10' do
        let(:cost) { 10.0 }

        context 'and volume=0' do
          let(:volume) { 0.0 }

          it 'is zero' do
            expect(@c.converter_api.storage_costs).to eq(0)
          end
        end

        context 'and volume=10' do
          let(:volume) { 10.0 }

          it 'is 100' do
            expect(@c.converter_api.storage_costs).to eq(100)
          end
        end
      end

      context 'with cost_per_mwh = nil' do
        let(:cost) { nil }

        context 'and volume=0' do
          let(:volume) { 0.0 }

          it 'is zero' do
            expect(@c.converter_api.storage_costs).to eq(0)
          end
        end

        context 'and volume=10' do
          let(:volume) { 10.0 }

          it 'is zero' do
            expect(@c.converter_api.storage_costs).to eq(0)
          end
        end
      end
    end # storage_costs
  end

end
