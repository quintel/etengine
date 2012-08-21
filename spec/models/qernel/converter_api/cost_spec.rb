require 'spec_helper'

module Qernel

  describe Qernel::ConverterApi, 'cost calculations' do

    before :each do
      @c = Qernel::Converter.new(id:1)
    end

    describe '#nominal_input_capacity' do

      it "should calculate correctly when electrical capacity and electrical efficiency are given" do
        @c.with electricity_output_conversion: 0.4, output_capacity_electricity: 800
        @c.converter_api.nominal_input_capacity.should == 2000
      end

      it "should calculate correctly when both heat and electrical capacity and heat and electrical efficiency are given" do
        @c.with electricity_output_conversion: 0.4, output_capacity_electricity: 800, heat_output_conversion: 0.1, output_capacity_heat: 400
        @c.converter_api.nominal_input_capacity.should == 2000
      end

      it "should calculate correctly when heat capacity and heat efficiency are given" do
        @c.with heat_output_conversion: 0.2, output_capacity_heat: 400
        @c.converter_api.nominal_input_capacity.should == 2000
      end

      it "should return zero when no efficiencies are set" do
        @c.with heat_output_conversion: nil, electricity_output_conversion: nil
        @c.converter_api.nominal_input_capacity.should == 0.0
      end
      
      it "should return zero when electrical efficiency and heat capacity not set" do
        @c.with heat_output_conversion: 0.2, electricity_output_conversion: nil
        @c.converter_api.nominal_input_capacity.should == 0.0
      end
      
      it "should return zero when heat efficiency and electrical capacity not set" do
        @c.with heat_output_conversion: nil, electricity_output_conversion: nil
        @c.converter_api.nominal_input_capacity.should == 0.0
      end

      it "should return zero when efficiencies are zero" do
        @c.with heat_output_conversion: 0, electricity_output_conversion: 0
        @c.converter_api.nominal_input_capacity.should == 0.0
      end

      it "should return zero when electrical capacity and heat capacity are not set" do
        @c.with output_capacity_heat: nil, output_capacity_electricity: nil, heat_output_conversion: 0.2, electricity_output_conversion: 0.4
        @c.converter_api.nominal_input_capacity.should == 0
      end
      
    end
    
  end

end
