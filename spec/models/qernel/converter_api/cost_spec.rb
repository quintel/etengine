require 'spec_helper'

module Qernel

  describe Qernel::ConverterApi, 'cost calculations' do

    before :each do
      @c = Qernel::Converter.new(id:1)
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
        @c.converter_api.input_capacity.should == 2000
      end

      it "should calculate correctly when only heat capacity and heat efficiency are given" do
        @c.with heat_output_conversion: 0.1, heat_output_capacity: 400
        @c.converter_api.input_capacity.should == 4000
      end

      it "should return zero when capacity and conversion are both zero" do
        @c.with electricity_output_capacity: 0, electricity_output_conversion: 0
        @c.converter_api.input_capacity.should == 0
        @c.with heat_output_capacity: 0, heat_and_cold_output_conversion: 0
        @c.converter_api.input_capacity.should == 0
      end

      it "should raise error when incomplete" do
        @c.with electricity_output_conversion: 0.4,
                electricity_output_capacity: nil,
                heat_and_cold_output_conversion: nil,
                heat_output_capacity: 400

        expect { @c.converter_api.input_capacity }.to raise_error
      end

      it "should raise error when capicity-e/eff-e != capacity-h/eff-h" do
        pending "Data validations of Converters upon loading / importing" do
          @c.with heat_output_capacity: 400, electricity_output_capacity: 1000, heat_and_cold_output_conversion: 0.2, electricity_output_conversion: 0.4
          expect { @c.converter_api.input_capacity }.to raise_error
        end
      end

    end

    describe '#total_cost' do

      it "should calculate correctly when values are given" do
        @c.with fixed_costs: 100, variable_costs: 200
        @c.converter_api.send(:total_costs).should == 300
      end

      it "should return nil when one of the two is missing" do
        @c.with fixed_costs: 100, variable_costs: nil
        @c.converter_api.send(:total_costs).should == nil
        @c.with fixed_costs: nil, variable_costs: 200
        @c.converter_api.send(:total_costs).should == nil
      end

    end

    describe '#fixed_costs' do

      it "should calculate correctly when values are given" do
        @c.with cost_of_capital: 100, depreciation_costs: 200, fixed_operation_and_maintenance_costs_per_year: 300
        @c.converter_api.send(:fixed_costs).should == 600
      end

      it "should add correctly when cost_of_capital is nil" do
        pending "Data validations of Converters upon loading / importing" do
          @c.with cost_of_capital: nil, depreciation_costs: 200, fixed_operation_and_maintenance_costs_per_year: 300
          @c.converter_api.send(:fixed_costs).should == 500
        end
      end

      it "should add correctly when depreciation costs are nil" do
        pending "Data validations of Converters upon loading / importing" do
          @c.with cost_of_capital: 100, depreciation_costs: nil, fixed_operation_and_maintenance_costs_per_year: 300
          @c.converter_api.send(:fixed_costs).should == 400
        end
      end

      it "should add correctly when fixed O&M costs are nil" do
        pending "Data validations of Converters upon loading / importing" do
          @c.with cost_of_capital: 100, depreciation_costs: 200, fixed_operation_and_maintenance_costs_per_year: nil
          @c.converter_api.send(:fixed_costs).should == 300
        end
      end

    end

    describe '#cost_of_capital' do

      it "should calculate when all values are given" do
        @c.with average_investment: 100, wacc: 0.1, construction_time: 1, technical_lifetime: 10
        @c.converter_api.send(:cost_of_capital).should == 11
      end

      it "should handle nil values" do
        pending "Data validations of Converters upon loading / importing"
      end

      it "should raise error when technical life time is zero" do
        pending "Data validations of Converters upon loading / importing"
      end

      it "should raise error when construction time is zero" do
        pending "Data validations of Converters upon loading / importing"
      end

    end

    describe '#depreciation_costs' do
      it "should calculate when everything is set" do
        @c.with total_investment_over_lifetime: 100, technical_lifetime: 10
        @c.converter_api.send(:depreciation_costs).should == 10
      end

      it "should raise error when total_investment_costs < 0" do
        pending "error raising"
      end

      it "should raise error when technical_lifetime is 0 or nil" do
        pending "error raising"
      end
    end

    describe '#marginal_costs' do
      it "should calculate correctly when values are given" do
        @c.with variable_costs_per_typical_input: 100, electricity_output_conversion: 0.5
        @c.converter_api.send(:marginal_costs).should == 720000.0
      end
    end

    describe '#variable_costs' do
      it "should calculate correctly when values are given" do
        @c.with variable_costs_per_typical_input: 300, typical_input: 2
        @c.converter_api.send(:variable_costs).should == 600
      end
    end

    describe '#variable_costs_per_typical_input' do
      it "should calculate correctly when values are given" do
        @c.with weighted_carrier_cost_per_mj: 200, co2_emissions_costs_per_typical_input: 300, 
        variable_operation_and_maintenance_costs_per_typical_input: 400
        @c.converter_api.send(:variable_costs_per_typical_input).should == 900
      end
    end

    describe "#fuel_costs" do
      it "should calculate when everything is set" do
        @c.with total_investment_over_lifetime: 100, technical_lifetime: 10
        @c.converter_api.send(:depreciation_costs).should == 10
      end

      it "should return 0 when typical_input <= 0" do
        pending "error raising"
      end

      it "should raise error when typical_input is nil" do
        pending "statistical converters and data validation"
      end
    end

    describe '#co2_emissions_costs' do
      it "should calculate when everything is set" do
        @c.with typical_input: 500, co2_emissions_costs_per_typical_input: 2
        @c.converter_api.send(:co2_emissions_costs).should == 1000
      end
    end

    describe '#co2_emissions_costs_per_typical_input' do
      it "should calculate when everything is set" do
        pending "correct syntax of spec"
        # @c.with typical_input: 500, weighted_carrier_co2_per_mj: 1, area.co2_price: 1, area.co2_percentage_free: 0, takes_part_in_ets: 1, free_co2_factor: 0
        # @c.converter_api.co2_emissions_costs_per_typical_input.should == 500
      end
      
      it "should handle nil values" do
        pending "Data validations of Converters upon loading / importing"
      end
    end

    describe '#variable_operation_and_maintenance_costs' do
      it "should calculate when everything is set" do
        @c.with variable_operation_and_maintenance_costs_per_typical_input: 500, typical_input: 2
        @c.converter_api.send(:variable_operation_and_maintenance_costs).should == 1000
      end
      
      it "should handle nil values" do
        pending "Data validations of Converters upon loading / importing"
      end
    end

    describe '#variable_operation_and_maintenance_costs_per_typical_input' do
      it "should calculate when everything is set" do
        @c.with variable_operation_and_maintenance_costs_per_full_load_hour: 500, 
        variable_operation_and_maintenance_costs_for_ccs_per_full_load_hour: 400,
        input_capacity: 2
        @c.converter_api.send(:variable_operation_and_maintenance_costs_per_typical_input).should == 0.125
      end
      
      it "should handle nil values" do
        pending "Data validations of Converters upon loading / importing"
      end
    end

    describe '#total_initial_investment' do
      it "should calculate when everything is set" do
        @c.with initial_investment: 500, ccs_investment: 100, cost_of_installing: 66
        @c.converter_api.total_initial_investment.should == 666
      end

      it "should handle nil values" do
        pending "Data validations of Converters upon loading / importing"
      end
    end
    
    describe '#total_investment_over_lifetime' do
      it "should calculate when everything is set" do
        @c.with total_initial_investment: 10000, decommissioning_costs: 5000
        @c.converter_api.total_investment_over_lifetime.should == 15000
      end
      
      it "should handle nil values" do
        pending "Data validations of Converters upon loading / importing"
      end
    end
  end

end
