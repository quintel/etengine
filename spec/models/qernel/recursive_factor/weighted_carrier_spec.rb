# frozen_string_literal: true

require 'spec_helper'

describe Qernel::RecursiveFactor::WeightedCarrier do
  let(:converter) { Qernel::Converter.new(id: 1) }

  def build_slot(converter, carrier, direction, conversion = 1.0)
    Qernel::Slot.new(
      1, converter, Qernel::Carrier.new(key: carrier), direction
    ).with(conversion: conversion)
  end

  describe '#weighted_carrier_cost_per_mj' do
    before do
      allow(converter).to receive(:recursive_factor_without_losses)
        .with(:weighted_carrier_cost_per_mj_factor)
        .and_return(4.0)
    end

    context 'with coal and gas outputs' do
      before do
        converter.add_slot(build_slot(converter, :coal, :output, 0.4))
        converter.add_slot(build_slot(converter, :gas, :output, 0.6))
        converter.with(waste_outputs: [:coal])
      end

      it 'ignores waste outputs' do
        expect(converter.send(:weighted_carrier_cost_per_mj)).to eq(2.4)
      end
    end

    context 'with coal, gas, and loss outputs' do
      before do
        converter.add_slot(build_slot(converter, :coal, :output, 0.3))
        converter.add_slot(build_slot(converter, :gas, :output, 0.5))
        converter.add_slot(build_slot(converter, :loss, :output, 0.2))

        converter.with(waste_outputs: [:coal])
      end

      it 'includes a costable share of loss' do
        # 2 from the gas, plus the gas share of the loss.
        # loss is 0.2, and gas is responsible for 0.625 (0.5 / 0.8) of
        # that = 0.5.
        expect(converter.send(:weighted_carrier_cost_per_mj)).to eq(2.5)
      end
    end
  end
end
