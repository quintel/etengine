require 'spec_helper'

describe Qernel::ConverterApi do

  before :each do
    @c = Qernel::Converter.new(id:1)
  end

  describe "#total_costs_per(unit)" do

    it "should calculate correctly when asked for :plant" do
      @c.with total_costs: 1000
      @c.converter_api.total_costs_per(:plant).should == 1000
    end

    it "should calculate correctly when asked for :converter" do
      @c.with total_costs: 1000, number_of_units: 10
      @c.converter_api.total_costs_per(:converter).should == 10_000
    end

    it "should calculate correctly when asked for :mwh_input" do
      @c.with total_costs: 1000, number_of_units: 10, demand: 50
      @c.converter_api.total_costs_per(:mwh_input).should == 2 / SECS_PER_HOUR
    end

  end

end
