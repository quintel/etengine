require 'spec_helper'

describe Qernel::NodeApi do

  before :each do
    @c = Qernel::Node.new(id:1)
  end

  describe "#total_costs_per(unit)" do

    it "should calculate correctly when asked for :plant" do
      @c.with total_costs: 1000.0
      expect(@c.node_api.total_costs_per(:plant)).to eq(1000.0)
    end

    it "should calculate correctly when asked for :node" do
      @c.with total_costs: 1000.0, number_of_units: 10.0
      expect(@c.node_api.total_costs_per(:node)).to eq(10_000.0)
    end

    it "should calculate correctly when asked for :mw_heat" do
      @c.with total_costs: 1000.0, heat_output_capacity: 200.0
      expect(@c.node_api.total_costs_per(:mw_heat)).to eq(5.0)
    end

    it "should calculate correctly given integers when asked for :mw_heat" do
      @c.with total_costs: 1000, heat_output_capacity: 400
      expect(@c.node_api.total_costs_per(:mw_heat)).to eq(2.5)
    end

    it "should calculate correctly when asked for :mwh_electricity" do
      @c.with total_costs: 1000.0, typical_electricity_output: 3600.0
      expect(@c.node_api.total_costs_per(:mwh_electricity)).to eq(1000.0)
    end

    it "should raise ArgumentError when asked for something weird" do
      @c.with total_costs: 1000.0
      expect { @c.node_api.total_costs_per(:arnold_schwarzenegger) }.to \
        raise_error(ArgumentError)
    end

  end

end
