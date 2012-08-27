require 'spec_helper'

module Qernel

  describe Qernel::ConverterApi, 'cost calculations' do

    before :each do
      @c = Qernel::Converter.new(id:1)
    end

    describe '#nominal_input_capacity' do
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
        @c.converter_api.nominal_input_capacity.should == 2000
      end

      it "should calculate correctly when only heat capacity and heat efficiency are given" do
        @c.with heat_output_conversion: 0.1, heat_output_capacity: 400
        @c.converter_api.nominal_input_capacity.should == 4000
      end

      it "should return zero when all variables are not set or zero" do
        pending "Implementation to rescue upon nil" do
          @c.with heat_output_capacity: nil, electricity_output_capacity: 0, heat_output_conversion: nil, electricity_output_conversion: 0
          @c.converter_api.nominal_input_capacity.should == 0
        end
      end

      it "should raise error when incomplete" do
        pending "Implementation of raising error" do
          @c.with electricity_output_conversion: 0.4, electricity_output_capacity: nil, heat_output_conversion: nil, heat_output_capacity: 400
          expect { @c.converter_api.nominal_input_capacity }.to raise_error
        end
      end

      it "should raise error when capicity-e/eff-e != capacity-h/eff-h" do
        pending "Implementation of raising error" do
          @c.with heat_output_capacity: 400, electricity_output_capacity: 1000, heat_output_conversion: 0.2, electricity_output_conversion: 0.4
          expect { @c.converter_api.nominal_input_capacity }.to raise_error
        end
      end

    end

    describe '#effective_input_capacity' do

      it "should calculate correctly when nominal_input_capacity and average_effective_output_of_nominal_capacity_over_lifetime are set" do
        @c.with nominal_input_capacity: 100, average_effective_output_of_nominal_capacity_over_lifetime: 0.99
        @c.converter_api.effective_input_capacity.should == 99
      end

      it "should calculate correctly when nominal_input_capacity is zero" do
        @c.with nominal_input_capacity: 0, average_effective_output_of_nominal_capacity_over_lifetime: 0.99
        @c.converter_api.effective_input_capacity.should == 0.0
      end

      it "should calculate correctly when nominal_input capacity is not set" do
        pending "rescue when nil" do
          @c.with nominal_input_capacity: nil, average_effective_output_of_nominal_capacity_over_lifetime: 0.99
          @c.converter_api.effective_input_capacity.should == 0.0
        end
      end

      it "should calculate correctly when average_effective_output_of_nominal_capacity_over_lifetime is zero" do
        @c.with nominal_input_capacity: 100, average_effective_output_of_nominal_capacity_over_lifetime: 0
        @c.converter_api.effective_input_capacity.should == 0.0
      end

      it "should return nominal_input_capacity when average_effective_output_of_nominal_capacity_over_lifetime is nil" do
        pending "Assume 100% (1.0) when nil" do
          @c.with electricity_output_conversion: 0.4, electricity_output_capacity: 800, average_effective_output_of_nominal_capacity_over_lifetime: nil
          @c.converter_api.effective_input_capacity.should == @c.converter_api.nominal_input_capacity
        end
      end

      it "should return nominal_input_capacity when average_effective_output_of_nominal_capacity_over_lifetime is 100%" do
        @c.with electricity_output_conversion: 0.4, heat_output_capacity: 800, average_effective_output_of_nominal_capacity_over_lifetime: 1
        @c.converter_api.effective_input_capacity.should == @c.converter_api.nominal_input_capacity
      end

    end

    describe '#total_cost' do

      it "should calculate correctly when values are given" do
        @c.with fixed_costs: 100, variable_costs: 200
        @c.converter_api.total_costs.should == 300
      end

      it "should take fixed costs when variable costs are nil" do
        @c.with fixed_costs: 100, variable_costs: nil
        @c.converter_api.total_costs.should == 100
      end

      it "should take variable costs when fixed costs are nil" do
        @c.with fixed_costs: nil, variable_costs: 200
        @c.converter_api.total_costs.should == 200
      end

    end

    describe '#fixed_costs' do

      it "should calculate correctly when values are given" do
        @c.with cost_of_capital: 100, depreciation_costs: 200, fixed_operation_and_maintenance_costs: 300
        @c.converter_api.fixed_costs.should == 600
      end

      it "should add correctly when cost_of_capital is nil" do
        pending "rescue when nil" do
          @c.with cost_of_capital: nil, depreciation_costs: 200, fixed_operation_and_maintenance_costs: 300
          @c.converter_api.fixed_costs.should == 500
        end
      end

      it "should add correctly when depreciation costs are nil" do
        pending "rescue when nil" do
          @c.with cost_of_capital: 100, depreciation_costs: nil, fixed_operation_and_maintenance_costs: 300
          @c.converter_api.fixed_costs.should == 400
        end
      end

      it "should add correctly when fixed O&M costs are nil" do
        pending "rescue when nil" do
          @c.with cost_of_capital: 100, depreciation_costs: 200, fixed_operation_and_maintenance_costs: nil
          @c.converter_api.fixed_costs.should == 300
        end
      end

    end

    describe '#cost_of_capital' do
      # should calculate when everything is set
      # should raise error when wacc is zero (pending error raising)
      # should raise error when technical lifetime is 0 or nil (pending error raising)
      # should assume 0 when construction time is nil (pending rescue on nil)
    end

    describe '#depreciation_costs' do
      # should calculate when everything is set
      # should raise error when total_investment_costs - residual_value < 0 (pending error raising)
      # should assume 0 when residual_value is nil
      # should raise error when technical_lifetime is 0 or nil
    end

    describe '#variable_costs' do
      it "should calculate correctly when values are given" do
        @c.with fuel_costs: 100, co2_emissions_costs: 200, variable_operation_and_maintenance_costs: 300
        @c.converter_api.variable_costs.should == 600
      end

      it "should add correctly when cost_of_capital is nil" do
        pending "rescue when nil" do
          @c.with fuel_costs: nil, co2_emissions_costs: 200, variable_operation_and_maintenance_costs: 300
          @c.converter_api.variable_costs.should == 500
        end
      end

      it "should add correctly when depreciation costs are nil" do
        pending "rescue when nil" do
          @c.with fuel_costs: 100, co2_emissions_costs: nil, variable_operation_and_maintenance_costs: 300
          @c.converter_api.variable_costs.should == 400
        end
      end

      it "should add correctly when fixed O&M costs are nil" do
        pending "rescue when nil" do
          @c.with fuel_costs: 100, co2_emissions_costs: 200, variable_operation_and_maintenance_costs: nil
          @c.converter_api.variable_costs.should == 300
        end
      end
    end

    describe "#fuel_costs" do
      # should calculate when everything is set
      # should return 0 when real_number_of_units <= 0
      # should raise error when real_number_of_units is nil (pending error raising)
    end

    describe '#co2_emissions_costs' do
      # DEBT: first refactor method
    end

    describe '#variable_operations_and_maintenance_costs' do
      # should calculate when everything is set
      # should return 0 when full_load_hours is nil (pending)
      # should treat everything nil as 0 in the calculation (pending)
    end

    describe '#initial_investment_costs' do
      # should calculate when everything is set
      # should treat nil as 0 (pending rescue on nil)
    end

    describe '#average_investment_costs' do
      # should calculate when everything is set
      # should treat nil as 0 (pending rescue on nil)
    end

    describe '#total_investment_costs' do
      # should calculate when everything is set
      # should treat nil as 0 (pending rescue on nil)
    end

  end

end
