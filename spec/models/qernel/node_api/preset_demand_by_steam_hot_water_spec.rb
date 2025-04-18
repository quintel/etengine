require 'spec_helper'

module Qernel
  describe NodeApi do
    let(:node) { FactoryBot.build(:node).with({}) }

    it 'updating node#preset_demand_by_steam_hot_water_production = takes into account conversion' do
      node.add_slot(Slot.new(1, nil, Carrier.new(key: :steam_hot_water), :output).with(conversion: 0.7))
      node.query.preset_demand_by_steam_hot_water_production = 1000.0

      expect(node.preset_demand).to eq(1000.0 / 0.7)
    end

    it 'raises an error if no steam hot water node found' do
      node.add_slot(Slot.new(1, nil, Carrier.new(key: :gas), :output).with(conversion: 0.7))

      expect { node.query.preset_demand_by_steam_hot_water_production = 1000.0 }
        .to raise_error(/could not find steam_hot_water output/)
    end
  end
end
