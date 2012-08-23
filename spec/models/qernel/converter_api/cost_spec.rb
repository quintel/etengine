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
      #  0.4    0.1    800    400     2000   e takes precedence over h
      #  nil    0.1    nil    400     4000
      #  nil    nil    800    400        0
      #  nil    0.1    800    nil        0
      #  0.4    nil    nil    400        0
      #  0.4    0.2    nil    nil        0
      #  0.4    0.2    nil    nil        0
      #    0    0     800       0        ?
      #

      it "should calculate correctly when electrical capacity and electrical efficiency are given" do
        @c.with electricity_output_conversion: 0.4, electricity_output_capacity: 800
        @c.converter_api.nominal_input_capacity.should == 2000
      end

      it "should calculate correctly when both heat and electrical capacity and heat and electrical efficiency are given" do
        @c.with electricity_output_conversion: 0.4, electricity_output_capacity: 800, heat_output_conversion: 0.1, heat_output_capacity: 400
        @c.converter_api.nominal_input_capacity.should == 2000
      end

      it "should calculate correctly when heat capacity and heat efficiency are given" do
        @c.with heat_output_conversion: 0.1, heat_output_capacity: 400
        @c.converter_api.nominal_input_capacity.should == 4000
      end

      it "should return zero when no efficiencies are set" do
        @c.with heat_output_conversion: nil, electricity_output_conversion: nil, electricity_output_capacity: 800, heat_output_capacity: 400
        @c.converter_api.nominal_input_capacity.should == 0.0
      end
      
      it "should return zero when electrical efficiency and heat capacity are not set" do
        @c.with heat_output_conversion: 0.1, electricity_output_conversion: nil, electricity_output_capacity: 800, heat_output_capacity: nil
        @c.converter_api.nominal_input_capacity.should == 0.0
      end
      
      it "should return zero when heat efficiency and electrical capacity not set" do
        @c.with heat_output_conversion: nil, electricity_output_conversion: 0.4, electricity_output_capacity: nil, heat_output_capacity: 400
        @c.converter_api.nominal_input_capacity.should == 0.0
      end

      it "should return zero when efficiencies are zero" do
        @c.with heat_output_conversion: 0, electricity_output_conversion: 0, heat_output_capacity: 400, electricity_output_capacity: 800
        @c.converter_api.nominal_input_capacity.should == 0.0
      end

      it "should return zero when electrical capacity and heat capacity are not set" do
        @c.with heat_output_capacity: nil, electricity_output_capacity: nil, heat_output_conversion: 0.2, electricity_output_conversion: 0.4
        @c.converter_api.nominal_input_capacity.should == 0
      end
      
      it "should should raise an error when electrical efficiency is 0" do
        @c.with heat_output_capacity: nil, electricity_output_capacity: 800, heat_output_conversion: nil, electricity_output_conversion: 0
        lambda { @c.converter_api.nominal_input_capacity }.should raise_error(ZeroDivisionError)
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
        @c.with nominal_input_capacity: nil, average_effective_output_of_nominal_capacity_over_lifetime: 0.99
        @c.converter_api.effective_input_capacity.should == 0.0
      end
      
      it "should calculate correctly when average_effective_output_of_nominal_capacity_over_lifetime is zero" do
        @c.with nominal_input_capacity: 100, average_effective_output_of_nominal_capacity_over_lifetime: 0
        @c.converter_api.effective_input_capacity.should == 0.0
      end
      
      it "should return nominal_input_capacity when average_effective_output_of_nominal_capacity_over_lifetime is nil" do
        @c.with electricity_output_conversion: 0.4, electricity_output_capacity: 800, average_effective_output_of_nominal_capacity_over_lifetime: nil
        @c.converter_api.effective_input_capacity.should == @c.converter_api.nominal_input_capacity
      end

      it "should return nominal_input_capacity when average_effective_output_of_nominal_capacity_over_lifetime is 100%" do
        @c.with electricity_output_conversion: 0.4, heat_output_capacity: 800, average_effective_output_of_nominal_capacity_over_lifetime: 1
        @c.converter_api.effective_input_capacity.should == @c.converter_api.nominal_input_capacity
      end

    end
    
    describe '#total_cost' do
    
      it "should calculate correctly when values are given" do
        @c.with fixed_costs: 100, variable_costs: 200
        @c.converter_api.total_cost.should == 300
      end
      
      it "should take fixed costs when variable costs are nil" do
        @c.with fixed_costs: 100, variable_costs: nil
        @c.converter_api.total_cost.should == 100
      end
      
      it "should take variable costs when fixed costs are nil" do
        @c.with fixed_costs: nil, variable_costs: 200
        @c.converter_api.total_cost.should == 200
      end
    
    end
    
    describe '#fixed_costs' do
    
      it "should calculate correctly when values are given" do
        @c.with cost_of_capital: 100, depreciation_costs: 200, fixed_operation_and_maintenance_costs: 300
        @c.converter_api.fixed_costs.should == 600
      end
      
      it "should add correctly when cost_of_capital is nil" do
        @c.with cost_of_capital: nil, depreciation_costs: 200, fixed_operation_and_maintenance_costs: 300
        @c.converter_api.fixed_costs.should == 500
      end
      
      it "should add correctly when depreciation costs are nil" do
        @c.with cost_of_capital: 100, depreciation_costs: nil, fixed_operation_and_maintenance_costs: 300
        @c.converter_api.fixed_costs.should == 400
      end
      
      it "should add correctly when fixed O&M costs are nil" do
        @c.with cost_of_capital: 100, depreciation_costs: 200, fixed_operation_and_maintenance_costs: nil
        @c.converter_api.fixed_costs.should == 300
      end
    
    end
    
    describe '#cost_of_capital' do
    end
    
  end

end
