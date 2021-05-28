# frozen_string_literal: true

require 'spec_helper'

# This creates examples which test the primary demand and primary_demand_of_* methods for all three
# nodes. Include the shares examples within a context, defining the expected primary demands in
# `let` blocks.
#
#     include_examples 'expected primary demand values' do
#       let(:expected_left_demand) { 50 }
#       let(:expected_middle_demand) { 100 }
#       let(:expected_right_demand) { 100 }
#     end
#
RSpec.shared_examples_for 'expected primary demand values' do
  it 'the left node has the expected primary_demand' do
    expect(graph.node(:left).query.primary_demand).to eq(expected_left_demand)
  end

  it 'the left node has the expected primary_demand_of_natural_gas' do
    expect(graph.node(:left).query.primary_demand_of_natural_gas).to eq(expected_left_demand)
  end

  it 'the left node no primary_demand_of_coal' do
    expect(graph.node(:left).query.primary_demand_of_coal).to eq(0)
  end

  it 'the middle node has the expected primary_demand' do
    expect(graph.node(:middle).query.primary_demand).to eq(expected_middle_demand)
  end

  it 'the middle node has the expected primary_demand_of_natural_gas' do
    expect(graph.node(:middle).query.primary_demand_of_natural_gas).to eq(expected_middle_demand)
  end

  it 'the middle node no primary_demand_of_coal' do
    expect(graph.node(:middle).query.primary_demand_of_coal).to eq(0)
  end

  it 'the right node has the expected primary_demand' do
    expect(graph.node(:right).query.primary_demand).to eq(expected_right_demand)
  end

  it 'the right node has the expected primary_demand_of_natural_gas' do
    expect(graph.node(:right).query.primary_demand_of_natural_gas).to eq(expected_right_demand)
  end

  it 'the right node no primary_demand_of_coal' do
    expect(graph.node(:right).query.primary_demand_of_coal).to eq(0)
  end
end

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
      builder.add(:right, demand: 100, groups: %i[primary_energy_demand])

      builder.connect(:right, :middle, :natural_gas, type: :share)
      builder.connect(:middle, :left, :natural_gas, type: :share)
    end
  end

  let(:graph) { builder.to_qernel }

  context 'when all shares and conversions are 1.0' do
    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 100 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end
  end

  context 'when the right-most node is connected to an input' do
    # Asserts that recursion stops when reaching the primary demand node.
    before do
      builder.add(:input)
      builder.connect(:input, :right, :natural_gas)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 100 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end

    it 'the input node has no primary_demand' do
      expect(graph.node(:input).query.primary_demand).to eq(0)
    end

    it 'the input node has no primary_demand_of_natural_gas' do
      expect(graph.node(:input).query.primary_demand_of_natural_gas).to eq(0)
    end
  end

  context 'when the right-most node does not belong to the PD group' do
    # Asserts that recursion stops when reaching the primary demand node.
    before do
      builder.node(:right).set(:groups, [])
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 0 }
      let(:expected_middle_demand) { 0 }
      let(:expected_right_demand) { 0 }
    end
  end

  context 'when the middle node has a conversion of 2.0' do
    before do
      builder.node(:middle).slots.out(:natural_gas).set(:share, 2.0)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 100 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end
  end

  context 'when the middle node has a conversion of 0.5' do
    before do
      builder.node(:middle).slots.out(:natural_gas).set(:share, 0.5)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 50 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end
  end

  context 'when the middle node has two output conversions, each of 0.6' do
    # When the sum of output conversions exceed 1.0, the conversion is normalized so that it
    # represents a percentage of the total (two outputs with conversion of 0.6 result in effective
    # conversions of 0.5 each).
    before do
      builder.add(:middle_elec)
      builder.connect(:middle, :middle_elec, :electricity)

      builder.node(:middle).slots.out(:natural_gas).set(:share, 0.6)
      builder.node(:middle).slots.out(:electricity).set(:share, 0.6)
    end

    # https://github.com/quintel/etengine/issues/1172
    xit 'the left node has primary_demand of 50' do
      expect(graph.node(:left).query.primary_demand).to eq(50.0)
    end

    # https://github.com/quintel/etengine/issues/1172
    xit 'the left node has primary_demand_of_natural_gas of 50' do
      expect(graph.node(:left).query.primary_demand_of_natural_gas).to eq(50.0)
    end

    it 'the middle node has primary_demand of 100' do
      expect(graph.node(:middle).query.primary_demand).to eq(100.0)
    end

    it 'the middle node has primary_demand_of_natural_gas of 100' do
      expect(graph.node(:middle).query.primary_demand_of_natural_gas).to eq(100.0)
    end

    it 'the right node has primary_demand of 100' do
      expect(graph.node(:right).query.primary_demand).to eq(100.0)
    end

    it 'the right node has primary_demand_of_natural_gas of 100' do
      expect(graph.node(:right).query.primary_demand_of_natural_gas).to eq(100.0)
    end
  end

  context 'when the right (PD) node has 20% loss' do
    # Energy lost on the PD node itself (but not others on the path) is not counted towards primary
    # demand.
    #
    # https://github.com/quintel/etengine/issues/1147
    before do
      builder.node(:right).slots.out(:natural_gas).set(:share, 0.8)
      builder.node(:right).slots.out.add(:loss, share: 0.2)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 80 }
      let(:expected_middle_demand) { 80 }
      let(:expected_right_demand) { 80 }
    end
  end

  context 'when the middle node has 80% gas and 20% loss output' do
    # Similar to the above; but losses on the path are ignored.
    before do
      builder.node(:middle).slots.out(:natural_gas).set(:share, 0.8)
      builder.node(:middle).slots.out.add(:loss, share: 0.2)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 100 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end
  end

  context 'when the middle node has 80% gas and 20% electricity output' do
    # This is a variation on the above, where instead of loss on the middle node we have
    # electricity. This energy is _not_ ignored when calculating recursively as loss is.
    before do
      builder.node(:middle).slots.out(:natural_gas).set(:share, 0.8)
      builder.node(:middle).slots.out.add(:electricity, share: 0.2)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 80 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end
  end

  context 'when the left node has a sibling with equal demand of the same carrier' do
    before do
      builder.add(:sibling)
      builder.connect(:middle, :sibling, :natural_gas, parent_share: 0.5)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 50 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end
  end

  context 'when the left node has a sibling with equal demand of a different carrier' do
    before do
      builder.add(:sibling)
      builder.connect(:middle, :sibling, :electricity)
      builder.node(:middle).slots.out(:electricity).set(:share, 0.5)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 50 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end

    it 'the sibling node has primary_demand of 50' do
      expect(graph.node(:sibling).query.primary_demand).to eq(50.0)
    end

    it 'the sibling node has primary_demand_of_natural_gas of 50' do
      expect(graph.node(:sibling).query.primary_demand_of_natural_gas).to eq(50.0)
    end
  end

  context 'when the middle and right (PD) nodes both have 20% loss' do
    before do
      builder.node(:middle).slots.out(:natural_gas).set(:share, 0.8)
      builder.node(:middle).slots.out.add(:loss, share: 0.2)

      builder.node(:right).slots.out(:natural_gas).set(:share, 0.8)
      builder.node(:right).slots.out.add(:loss, share: 0.2)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 80 }
      let(:expected_middle_demand) { 80 }
      let(:expected_right_demand) { 80 }
    end
  end

  context 'with another level to the left with a different carrier' do
    before do
      builder.add(:far_left)
      builder.connect(:left, :far_left, :coal)
    end

    include_examples 'expected primary demand values' do
      let(:expected_left_demand) { 100 }
      let(:expected_middle_demand) { 100 }
      let(:expected_right_demand) { 100 }
    end

    it 'the far left node has primary_demand of 100' do
      expect(graph.node(:far_left).query.primary_demand).to eq(100.0)
    end

    it 'the far left node has primary_demand_of_natural_gas of 100' do
      expect(graph.node(:far_left).query.primary_demand_of_natural_gas).to eq(100.0)
    end
  end
end
