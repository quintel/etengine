# frozen_string_literal: true

require 'spec_helper'

# All primary demand specs are performed on a graph derived from this simple structure:
#
#     [left] <- [middle] <- [right]
#
# The "right" node belongs to the primary demand group. All edges are of the "natural_gas" carrier.
# Specs may define additional nodes, edges, or slots as needed.
RSpec.describe Qernel::RecursiveFactor::PrimaryDemand do
  let(:builder) do
    TestGraphBuilder.new.tap do |builder|
      builder.add(:left)
      builder.add(:middle)
      builder.add(:right, demand: 100)

      builder.connect(:right, :middle, :natural_gas, type: :share)
      builder.connect(:middle, :left, :transparent, type: :share)

      builder.carrier_attrs(
        :natural_gas,
        cost_per_mj: 2.0,
        co2_conversion_per_mj: 1.0
      )
    end
  end

  let(:graph) { builder.to_qernel }

  let(:left) { graph.node(:left) }
  let(:middle) { graph.node(:middle) }
  let(:right) { graph.node(:right) }

  context 'when all shares and conversions are 1.0' do
    it { expect(left).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(left).to have_query_value(:weighted_carrier_co2_per_mj, 1) }

    it { expect(middle).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(middle).to have_query_value(:weighted_carrier_co2_per_mj, 1) }

    it { expect(right).to have_query_value(:weighted_carrier_cost_per_mj, 0) }
    it { expect(right).to have_query_value(:weighted_carrier_co2_per_mj, 0) }
  end

  context 'when the middle node has outputs transparent=2.0' do
    before do
      builder.node(:middle).slots.out(:transparent).set(:share, 2.0)
    end

    it { expect(left).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(left).to have_query_value(:weighted_carrier_co2_per_mj, 1) }

    it { expect(middle).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(middle).to have_query_value(:weighted_carrier_co2_per_mj, 1) }

    it { expect(right).to have_query_value(:weighted_carrier_cost_per_mj, 0) }
    it { expect(right).to have_query_value(:weighted_carrier_co2_per_mj, 0) }
  end

  context 'when the middle node has outputs transparent=0.6 passthrough=0.6' do
    before do
      builder.node(:middle).slots.out(:transparent).set(:share, 0.6)
      builder.node(:middle).slots.out.add(:passthrough, share: 0.6)
    end

    it { expect(left).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(left).to have_query_value(:weighted_carrier_co2_per_mj, 1) }

    it { expect(middle).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(middle).to have_query_value(:weighted_carrier_co2_per_mj, 1) }

    it { expect(right).to have_query_value(:weighted_carrier_cost_per_mj, 0) }
    it { expect(right).to have_query_value(:weighted_carrier_co2_per_mj, 0) }
  end

  context 'when the right node has outputs natural_gas=0.6 coal=0.6' do
    before do
      builder.node(:right).slots.out(:natural_gas).set(:share, 0.6)
      builder.node(:right).slots.out.add(:coal, share: 0.6)
    end

    it { expect(left).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(left).to have_query_value(:weighted_carrier_co2_per_mj, 1) }

    it { expect(middle).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(middle).to have_query_value(:weighted_carrier_co2_per_mj, 1) }

    it { expect(right).to have_query_value(:weighted_carrier_cost_per_mj, 0) }
    it { expect(right).to have_query_value(:weighted_carrier_co2_per_mj, 0) }
  end

  context 'when the middle node has outputs transparent=0.5 loss=0.5' do
    before do
      builder.node(:middle).slots.out.add(:loss, share: 0.5)
      builder.node(:middle).slots.out(:transparent).set(:share, 0.5)
    end

    it { expect(left).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(left).to have_query_value(:weighted_carrier_co2_per_mj, 1) }
  end

  context 'when the middle node has two output edges, each with a share of 0.5' do
    before do
      builder.connect(:middle, :left_sibling, :transparent, parent_share: 0.5, type: :share)
      builder.edge(:middle, :left).set(:parent_share, 0.5)
    end

    it { expect(left).to have_query_value(:weighted_carrier_cost_per_mj, 2) }
    it { expect(left).to have_query_value(:weighted_carrier_co2_per_mj, 1) }
  end

  context 'when the middle node has an extra 100 coal input' do
    before do
      builder.add(:coal_production, demand: 100)
      builder.connect(:coal_production, :middle, :coal)

      builder.carrier_attrs(
        :coal,
        cost_per_mj: 20.0,
        co2_conversion_per_mj: 10.0
      )
    end

    it do
      expect(left).to have_query_value(
        :weighted_carrier_cost_per_mj,
        2 * 0.5 + # From natural_gas
          20 * 0.5 # From coal
      )
    end

    it do
      expect(left).to have_query_value(
        :weighted_carrier_co2_per_mj,
        1 * 0.5 + # From natural_gas
          10 * 0.5 # From coal
      )
    end
  end

  context 'when the middle node has an extra 100 coal input and inputs natural_gas=0.6 coal=0.6' do
    before do
      builder.add(:coal_production, demand: 100)
      builder.connect(:coal_production, :middle, :coal)

      builder.carrier_attrs(
        :coal,
        cost_per_mj: 20.0,
        co2_conversion_per_mj: 10.0
      )

      builder.node(:middle).slots.in(:natural_gas).set(:share, 0.6)
      builder.node(:middle).slots.in(:coal).set(:share, 0.6)
    end

    it do
      expect(left).to have_query_value(
        :weighted_carrier_cost_per_mj,
        2 * 0.6 + # From natural_gas
          20 * 0.6 # From coal
      )
    end

    it do
      expect(left).to have_query_value(
        :weighted_carrier_co2_per_mj,
        1 * 0.6 + # From natural_gas
          10 * 0.6 # From coal
      )
    end
  end
end
