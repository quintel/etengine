# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::Hydrogen::Calculator do
  let(:calculator) { described_class.new(demand, supply) }

  context 'with no demand or supply' do
    let(:demand) { [] }
    let(:supply) { [] }

    it 'has no surplus' do
      expect(calculator.surplus).to eq([])
    end

    it 'has no cumulative surplus' do
      expect(calculator.cumulative_surplus).to eq([])
    end

    it 'has no storage' do
      expect(calculator.storage_volume).to eq([])
    end
  end

  context 'with constant 5 demand, 5 supply' do
    let(:demand) { [5.0] * 10 }
    let(:supply) { [5.0] * 10 }

    it 'has no surplus' do
      expect(calculator.surplus).to eq([0.0] * 10)
    end

    it 'has no cumulative surplus' do
      expect(calculator.cumulative_surplus).to eq([0.0] * 10)
    end

    it 'has no storage' do
      expect(calculator.storage_volume).to eq([0.0] * 10)
    end
  end

  context 'with constant 5 demand, variable (1-41) supply' do
    let(:demand) { [5.0] * 10 }
    let(:supply) { [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 41.0, 1.0, 1.0] }

    it 'has surplus of -4 and 36' do
      expect(calculator.surplus).to eq([
        -4, -4, -4, -4, -4, -4, -4, 36, -4, -4
      ])
    end

    it 'has cumulative surplus' do
      expect(calculator.cumulative_surplus).to eq([
        -4, -8, -12, -16, -20, -24, -28, 8, 4, 0
      ])
    end

    it 'has storage' do
      expect(calculator.storage_volume).to eq([
        24, 20, 16, 12, 8, 4, 0, 36, 32, 28
      ])
    end

    it 'has storage input' do
      expect(calculator.storage_in).to eq([0, 0, 0, 0, 0, 0, 0, 36, 0, 0])
    end

    it 'has storage output' do
      expect(calculator.storage_out).to eq([4, 4, 4, 4, 4, 4, 4, 0, 4, 4])
    end
  end

  context 'with variable demand, constant 5 supply' do
    let(:demand) { [8.3, 9.3, 6.3, 3.3, 1.3, 1.3, 2.3, 4.3, 6.3, 7.3] }
    let(:supply) { [5.0] * 10 }

    it 'has surplus' do
      expect(calculator.surplus.map { |v| v.round(1) }).to eq([
        -3.3, -4.3, -1.3, 1.7, 3.7, 3.7, 2.7, 0.7, -1.3, -2.3
      ])
    end

    it 'has cumulative surplus' do
      expect(calculator.cumulative_surplus.map { |v| v.round(1) })
        .to eq([
          -3.3, -7.6, -8.9, -7.2, -3.5, 0.2, 2.9, 3.6, 2.3, 0.0
        ])
    end

    it 'has storage' do
      expect(calculator.storage_volume.map { |v| v.round(1) }).to eq([
        5.6, 1.3, 0.0, 1.7, 5.4, 9.1, 11.8, 12.5, 11.2, 8.9
      ])
    end

    it 'has storage input' do
      expect(calculator.storage_in.map { |v| v.round(1) }).to eq([
        0, 0, 0, 1.7, 3.7, 3.7, 2.7, 0.7, 0, 0
      ])
    end

    it 'has storage output' do
      expect(calculator.storage_out.map { |v| v.round(1) }).to eq([
        3.3, 4.3, 1.3, 0, 0, 0, 0, 0, 1.3, 2.3
      ])
    end
  end

  context 'with variable demand and supply' do
    let(:demand) { [0.3, 0.3, 1.3, 3.3, 7.3, 10.3, 6.3, 2.3, 1.3, 0.3] }
    let(:supply) { [1.0, 1.0, 0.0, 3.0, 5.0, 8.0, 10.0, 4.0, 1.0, 0.0] }

    it 'has surplus' do
      expect(calculator.surplus.map { |v| v.round(1) }).to eq([
        0.7, 0.7, -1.3, -0.3, -2.3, -2.3, 3.7, 1.7, -0.3, -0.3
      ])
    end

    it 'has cumulative surplus' do
      expect(calculator.cumulative_surplus.map { |v| v.round(1) })
        .to eq([
          0.7, 1.4, 0.1, -0.2, -2.5, -4.8, -1.1, 0.6, 0.3, 0.0
        ])
    end

    it 'has storage' do
      expect(calculator.storage_volume.map { |v| v.round(1) }).to eq([
        5.5, 6.2, 4.9, 4.6, 2.3, 0.0, 3.7, 5.4, 5.1, 4.8
      ])
    end

    it 'has storage input' do
      expect(calculator.storage_in.map { |v| v.round(1) }).to eq([
        0.7, 0.7, 0.0, 0.0, 0.0, 0.0, 3.7, 1.7, 0.0, 0.0
      ])
    end

    it 'has storage output' do
      expect(calculator.storage_out.map { |v| v.round(1) }).to eq([
        0.0, 0.0, 1.3, 0.3, 2.3, 2.3, 0.0, 0.0, 0.3, 0.3
      ])
    end
  end
end
