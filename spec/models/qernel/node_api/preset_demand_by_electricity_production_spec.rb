require 'spec_helper'

module Qernel
  describe NodeApi do
    before do
      @node = Node.new(key: 'foo').with({})
    end

    it "updating node#preset_demand_by_electricity_production = takes into account conversion" do
      @node.add_slot Slot.new(1, nil, Carrier.new(key: :electricity), :output).with({conversion: 0.7})
      @node.query.preset_demand_by_electricity_production = 1000.0
      expect(@node.preset_demand).to eq(1000.0 / 0.7)
    end

    it "raises an error if no electricity node found" do
      @node.add_slot Slot.new(1, nil, Carrier.new(key: :gas), :output).with({conversion: 0.7})
      expect {
        @node.query.preset_demand_by_electricity_production = 1000.0
      }.to raise_error(/could not find an electricity output/)
    end
  end
end
