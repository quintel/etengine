# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::Base do
  let(:supplier) { FactoryBot.build(:node, key: :supplier) }
  let(:consumer) { FactoryBot.build(:node, key: :consumer) }
  let(:carrier)  { Qernel::Carrier.new(key: :network_gas) }
  let!(:edge)    { Qernel::Edge.new('', consumer, supplier, carrier, :share) }

  let(:edge_api) { edge.query }

  before do
    supplier.add_slot(Qernel::Slot.factory(nil, -1, supplier, carrier, :output))
    consumer.add_slot(Qernel::Slot.factory(nil, -1, consumer, carrier, :input))
  end

  describe 'primary_demand' do
    it 'returns the right node value, minus conversions' do
      edge_api.output.with(conversion: 0.5)

      allow(supplier.query).to receive(:primary_demand).and_return(40.0)
      allow(supplier.query).to receive(:loss_compensation_factor).and_return(1.0)
      allow(edge).to receive(:parent_share).and_return(0.25)

      # binding.pry

      expect(edge_api.primary_demand).to eq(5.0)
    end

    it 'returns the right node value, minus conversions adjusting for loss' do
      edge_api.output.with(conversion: 0.5)

      allow(supplier.query).to receive(:primary_demand).and_return(40.0)
      allow(supplier.query).to receive(:loss_compensation_factor).and_return(1.5)
      allow(edge).to receive(:parent_share).and_return(0.25)

      expect(edge_api.primary_demand).to eq(7.5)
    end

    it 'returns nil if the parent node value is nil' do
      allow(supplier.query).to receive(:primary_demand).and_return(nil)
      expect(edge_api.primary_demand).to be_nil
    end
  end

  describe 'primary_demand_of_carrier' do
    it 'returns the right node value, minus conversions' do
      edge_api.output.with(conversion: 0.5)

      allow(supplier.query).to receive(:primary_demand_of_carrier).with(:coal).and_return(40.0)
      allow(supplier.query).to receive(:loss_compensation_factor).and_return(1.0)
      allow(edge).to receive(:parent_share).and_return(0.25)

      expect(edge_api.primary_demand_of_carrier(:coal)).to eq(5.0)
    end

    it 'returns nil if the parent node value is nil' do
      allow(supplier.query).to receive(:primary_demand_of_carrier).with(:coal).and_return(nil)

      expect(edge_api.primary_demand_of_carrier(:coal)).to be_nil
    end
  end

  describe 'sustainability_share' do
    it 'returns the right node value, minus conversions' do
      edge.output.with(conversion: 0.5)

      allow(supplier.query).to receive(:sustainability_share).and_return(0.5)
      allow(edge).to receive(:parent_share).and_return(0.25)

      expect(edge_api.sustainability_share).to eq(0.5 * 0.5 * 0.25)
    end
  end
end
