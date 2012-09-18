require 'spec_helper'

describe Qernel::ConverterApi do

  before :each do
    @c = Qernel::Converter.new(id:1)
  end

  describe "#total_costs_per(unit)" do

    it "should calculate correctly when asked for :plant" do
      @c.with total_costs: 1000.0
      @c.converter_api.total_costs_per(:plant).should == 1000.0
    end

    it "should calculate correctly when asked for :converter" do
      @c.with total_costs: 1000.0, number_of_units: 10.0
      @c.converter_api.total_costs_per(:converter).should == 10_000.0
    end

    it "should calculate correctly when asked for :mw_heat" do
      @c.with total_costs: 1000.0, heat_output_capacity: 200.0
      @c.converter_api.total_costs_per(:mw_heat).should == 5.0
    end

    it "should calculate correctly given integers when asked for :mw_heat" do
      @c.with total_costs: 1000, heat_output_capacity: 400
      @c.converter_api.total_costs_per(:mw_heat).should == 2.5
    end

    it "should calculate correctly when asked for :mwh_electricity" do
      @c.with total_costs: 1000.0, typical_electricity_output: 3600.0
      @c.converter_api.total_costs_per(:mwh_electricity).should == 1000.0
    end

    it "should raise ArgumentError when asked for something weird" do
      @c.with total_costs: 1000.0
      expect { @c.converter_api.total_costs_per(:arnold_schwarzenegger) }.to \
        raise_error(ArgumentError)
    end

  end

end
