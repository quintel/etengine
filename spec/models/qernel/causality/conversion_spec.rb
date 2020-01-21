# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::Causality::Conversion do
  def create_slot(converter, carrier_key, direction, conversion)
    Qernel::Slot.new(
      0,
      converter,
      Qernel::Carrier.new(key: carrier_key),
      direction
    ).with(conversion: conversion)
  end

  context 'with input slots a=0.1 b=0.9 and output slots a=0.25 c=0.75' do
    # Creates a converter with two input and two output slots. The input slots
    # have conversions of 0.1 and 0.9, and the outputs slots 0.25 and 0.75.
    let(:converter) do
      converter = Qernel::Converter.new(key: :conv)

      converter.add_slot(create_slot(converter, :a, :input, 0.1))
      converter.add_slot(create_slot(converter, :b, :input, 0.9))

      converter.add_slot(create_slot(converter, :a, :output, 0.25))
      converter.add_slot(create_slot(converter, :c, :output, 0.75))

      converter
    end

    it 'converts between two inputs slots a->b' do
      expect(described_class.conversion(converter, :a, :input, :b, :input))
        .to eq(9)
    end

    it 'converts between two inputs slots b->a' do
      expect(described_class.conversion(converter, :b, :input, :a, :input))
        .to be_within(1e-4).of(0.1111)
    end

    it 'converts between two outputs slots a->c' do
      expect(described_class.conversion(converter, :a, :output, :c, :output))
        .to eq(3)
    end

    it 'converts between two outputs slots c->a' do
      expect(described_class.conversion(converter, :c, :output, :a, :output))
        .to be_within(1e-4).of(0.3333)
    end

    it 'converts from an input to an output slot a->a' do
      expect(described_class.conversion(converter, :a, :input, :a, :output))
        .to eq(2.5)
    end

    it 'converts from an input to an output slot b->c' do
      expect(described_class.conversion(converter, :b, :input, :c, :output))
        .to be_within(1e-4).of(0.8333)
    end

    it 'converts from an output to an input slot a->a' do
      expect(described_class.conversion(converter, :a, :output, :a, :input))
        .to eq(0.4)
    end

    it 'converts from an output to an input slot c->b' do
      expect(described_class.conversion(converter, :c, :output, :b, :input))
        .to eq(1.2)
    end

    it 'raises an error if the input slot does not exist' do
      expect { described_class.conversion(converter, :c, :output, :c, :input) }
        .to raise_error('No c input slot on conv')
    end

    it 'raises an error if the output slot does not exist' do
      expect { described_class.conversion(converter, :b, :output, :a, :input) }
        .to raise_error('No b output slot on conv')
    end
  end

  context 'with input slots a=0.0 and output slots a=0.0' do
    let(:converter) do
      converter = Qernel::Converter.new(key: :conv)

      converter.add_slot(create_slot(converter, :a, :input, 0.0))
      converter.add_slot(create_slot(converter, :a, :output, 0.0))

      converter
    end

    it 'converts from an input to an output slot a->a as 0.0' do
      expect(described_class.conversion(converter, :a, :output, :a, :input))
        .to eq(0.0)
    end
  end

  context 'with input slots a=0.0 and output slots a=1.0' do
    let(:converter) do
      converter = Qernel::Converter.new(key: :conv)

      converter.add_slot(create_slot(converter, :a, :input, 0.0))
      converter.add_slot(create_slot(converter, :a, :output, 1.0))

      converter
    end

    it 'converts from an input to an output slot a->a as 0.0' do
      expect(described_class.conversion(converter, :a, :output, :a, :input))
        .to eq(0.0)
    end
  end

  context 'with input slots a=1.0 and output slots a=0.0' do
    let(:converter) do
      converter = Qernel::Converter.new(key: :conv)

      converter.add_slot(create_slot(converter, :a, :input, 1.0))
      converter.add_slot(create_slot(converter, :a, :output, 0.0))

      converter
    end

    it 'converts from an input to an output slot a->a as 0.0' do
      expect(described_class.conversion(converter, :a, :output, :a, :input))
        .to eq(0.0)
    end
  end
end
