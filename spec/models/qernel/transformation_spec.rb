# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::Transformation do
  # Graph with the following stucture:
  #
  # [ electricity ] <---+             +---- [ natural_gas ]
  #                     |             v
  #   [ greengas ] <--[ transformation ] <-- [ hydrogen ]
  #
  # Hydrogen to greengas is not allowed
  #
  subject { described_class.new(transformation_node) }

  let(:builder) do
    TestGraphBuilder.new.tap do |builder|
      builder.add(:hydrogen_node, demand: 50)
      builder.add(:electricity_node, demand: 50)
      builder.add(:transformation_node, demand: 100)
      builder.add(:natural_gas_node, demand: 50)
      builder.add(:greengas_node, demand: 50)

      builder.connect(:hydrogen_node, :transformation_node, :hydrogen, type: :share)
      builder.node(:transformation_node).slots.in(:hydrogen).set(:share, 0.5)

      builder.connect(:gas_node, :transformation_node, :natural_gas, type: :share)
      builder.node(:transformation_node).slots.in(:natural_gas).set(:share, 0.5)

      builder.connect(:transformation_node, :greengas_node, :greengas, type: :share)
      builder.node(:transformation_node).slots.out(:greengas).set(:share, 0.5)

      builder.connect(:transformation_node, :electricity_node, :electricity, type: :share)
      builder.node(:transformation_node).slots.out(:electricity).set(:share, 0.5)
    end
  end

  let(:graph) { builder.to_qernel }
  let(:transformation_node) { graph.node(:transformation_node) }

  context 'when calculating the node' do
    before { subject.calculate }

    it 'nettifies the disallowed hydrogen input' do
      expect(transformation_node.input(:hydrogen).net_conversion).to be_zero
    end

    it 'adds the energy to the allowed carrier' do
      expect(transformation_node.input(:natural_gas).net_conversion).to eq(1.0)
    end
  end
end
