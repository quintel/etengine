require 'spec_helper'

module Qernel
  describe ConverterApi do
    before do
      @converter = Converter.new(key: 'foo').with({})
    end

    it "updating converter#preset_demand_by_electricity_production = takes into account conversion" do
      @converter.add_slot Slot.new(1, nil, Carrier.new(key: :electricity), :output).with({conversion: 0.7})
      @converter.query.preset_demand_by_electricity_production = 1000.0
      expect(@converter.preset_demand).to eq(1000.0 / 0.7)
    end

    it "raises an error if no electricity converter found" do
      @converter.add_slot Slot.new(1, nil, Carrier.new(key: :gas), :output).with({conversion: 0.7})
      expect {
        @converter.query.preset_demand_by_electricity_production = 1000.0
      }.to raise_error(/could not find an electricity output/)
    end
  end
end
