# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::MeritFacade::AlwaysOnBatteryPark do
  let(:storage) do
    Merit::Flex::Storage.new({
      availability: 1.0,
      input_capacity_per_unit: Float::INFINITY,
      key: :_none,
      number_of_units: 1.0,
      output_capacity_per_unit: Float::INFINITY,
      reserve_class: Merit::Flex::SimpleReserve,
      volume_per_unit: 0
    }.merge(storage_attrs))
  end

  let(:storage_attrs) { {} }

  # Production exactly meets the output capacity each hour.
  context 'with a constant 1 output and capacity of 1' do
    let(:tech) do
      described_class.new(
        production_curve: [1.0] * 4,
        output_capacity: 1.0,
        storage: storage
      )
    end

    it 'has a constant 1 output' do
      expect(tech.output_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has no storage input' do
      expect(tech.storage_input_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has no storage output' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has nothing stored' do
      expect(tech.storage_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 0, 0, 0])
    end
  end

  # Production exactly meets the output capacity each hour.
  context 'with a constant 2 output and capacity of 1' do
    let(:tech) do
      described_class.new(
        production_curve: [2.0] * 4,
        output_capacity: 1.0,
        storage: storage
      )
    end

    it 'has a constant 1 output' do
      expect(tech.output_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has no storage input' do
      expect(tech.storage_input_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has no storage output' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has nothing stored' do
      expect(tech.storage_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has constant 1.0 curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([1, 1, 1, 1])
    end
  end

  # Storage volume
  # --------------

  # Production exceeds the output capacity every hour and the reserve can store all the excess.
  context 'with constant output 2, capacity 1, and volume 4' do
    let(:tech) do
      described_class.new(
        production_curve: [2.0] * 4,
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 4.0 } }

    it 'has a constant 1 output' do
      expect(tech.output_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has constant 1 storage input' do
      expect(tech.storage_input_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has no storage output' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has increasing energy stored' do
      expect(tech.storage_curve.take(4)).to eq([1, 2, 3, 4])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 0, 0, 0])
    end
  end

  # Production exceeds the output capacity in alternating hours, with the reserve storing the
  # excess and discharging when the producer has no output.
  context 'with alternating output [2, 1], capacity 1, and volume 4' do
    let(:tech) do
      described_class.new(
        production_curve: [2.0, 0.0, 2.0, 0.0],
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 4.0 } }

    it 'has a constant 1 output' do
      expect(tech.output_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has alternating [1, 0] storage input' do
      expect(tech.storage_input_curve.take(4)).to eq([1, 0, 1, 0])
    end

    it 'has alternating [0, 1] storage output' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 1, 0, 1])
    end

    it 'has energy stored' do
      expect(tech.storage_curve.take(4)).to eq([1, 0, 1, 0])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 0, 0, 0])
    end
  end

  # Production exceeds the output capacity every hour and the reserve can store only some of the
  # excess. The rest is curtailed.
  context 'with constant output 2, capacity 1, and volume 1' do
    let(:tech) do
      described_class.new(
        production_curve: [2.0] * 4,
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 1.0 } }

    it 'has a constant 1 output' do
      expect(tech.output_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has initial 1 storage input, then 0 when full' do
      expect(tech.storage_input_curve.take(4)).to eq([1, 0, 0, 0])
    end

    it 'has no storage output' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has constant 1 energy stored' do
      expect(tech.storage_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has some curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 1, 1, 1])
    end
  end

  # Battery input capacity
  # ----------------------

  # * Limited by output capacity.
  # * No storage input capacity limit.
  context 'with constant output 3, capacity 1, volume 8' do
    let(:tech) do
      described_class.new(
        production_curve: [3.0] * 4,
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 8.0 } }

    it 'has a constant 1 output' do
      expect(tech.output_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has constant 2 storage input' do
      expect(tech.storage_input_curve.take(4)).to eq([2, 2, 2, 2])
    end

    it 'has no storage output' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has increasing energy stored' do
      expect(tech.storage_curve.take(4)).to eq([2, 4, 6, 8])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 0, 0, 0])
    end
  end

  # * Limited by output capacity.
  # * Limited by storage input capacity.
  context 'with constant output 3, capacity 1, volume 4, storage input capacity 1' do
    let(:tech) do
      described_class.new(
        production_curve: [3.0] * 4,
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 4.0, input_capacity_per_unit: 1.0 } }

    it 'has a constant 1 output' do
      expect(tech.output_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has constant 1 storage input' do
      expect(tech.storage_input_curve.take(4)).to eq([1, 1, 1, 1])
    end

    it 'has no storage output' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 0, 0, 0])
    end

    it 'has increasing energy stored' do
      expect(tech.storage_curve.take(4)).to eq([1, 2, 3, 4])
    end

    it 'has constant 1 curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([1, 1, 1, 1])
    end
  end

  # Battery output capacity
  # -----------------------

  # * Limited by output capacity.
  # * No storage limits.
  context 'with initial output 4, capacity 1, volume 10' do
    let(:tech) do
      described_class.new(
        production_curve: [4.0, 0, 0, 0, 0, 0],
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 10.0 } }

    it 'has a constant 1 output until the battery is empty' do
      expect(tech.output_curve.take(6)).to eq([1, 1, 1, 1, 0, 0])
    end

    it 'has storage input [3, 0, 0, 0, 0, 0]' do
      expect(tech.storage_input_curve.take(6)).to eq([3, 0, 0, 0, 0, 0])
    end

    it 'has storage output [0, 1, 1, 1, 0, 0]' do
      expect(tech.storage_output_curve.take(6)).to eq([0, 1, 1, 1, 0, 0])
    end

    it 'has storage [2, 1, 0, 0, 0, 0]' do
      expect(tech.storage_curve.take(6)).to eq([3, 2, 1, 0, 0, 0])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(6)).to eq([0, 0, 0, 0, 0, 0])
    end
  end

  # * Limited by output capacity.
  # * Ultimately limited by storage volume.
  context 'with initial output 4, capacity 1, volume 2' do
    let(:tech) do
      described_class.new(
        production_curve: [4.0, 0, 0, 0],
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 2.0 } }

    it 'has a constant 1 output until the battery is empty' do
      expect(tech.output_curve.take(4)).to eq([1, 1, 1, 0])
    end

    it 'has storage input [2, 0, 0, 0]' do
      expect(tech.storage_input_curve.take(4)).to eq([2, 0, 0, 0])
    end

    it 'has storage output [0, 1, 1, 1]' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 1, 1, 0])
    end

    it 'has storage [2, 1, 0, 0]' do
      expect(tech.storage_curve.take(4)).to eq([2, 1, 0, 0])
    end

    it 'has initial curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([1, 0, 0, 0])
    end
  end

  # * Limited by output capacity.
  # * Ultimately limited by storage output capacity.
  context 'with initial output 4, capacity 2, volume 4, storage output capacity 1' do
    let(:tech) do
      described_class.new(
        production_curve: [4.0, 0, 0, 0],
        output_capacity: 2.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 4.0, output_capacity_per_unit: 1.0 } }

    it 'has output until the battery is empty' do
      expect(tech.output_curve.take(4)).to eq([2, 1, 1, 0])
    end

    it 'has storage input [2, 0, 0, 0]' do
      expect(tech.storage_input_curve.take(4)).to eq([2, 0, 0, 0])
    end

    it 'has storage output [0, 1, 1, 0]' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 1, 1, 0])
    end

    it 'has storage [2, 1, 0, 0]' do
      expect(tech.storage_curve.take(4)).to eq([2, 1, 0, 0])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 0, 0, 0])
    end
  end

  # * Ultimately limited by output capacity.
  # * Limited by storage output capacity.
  context 'with initial output 4, capacity 3, volume 10, storage output capacity 5' do
    let(:tech) do
      described_class.new(
        production_curve: [10.0, 0, 0, 0],
        output_capacity: 3.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 10.0, output_capacity_per_unit: 5.0 } }

    it 'has output until the battery is empty' do
      expect(tech.output_curve.take(4)).to eq([3, 3, 3, 1])
    end

    it 'has storage input [7, 0, 0, 0]' do
      expect(tech.storage_input_curve.take(4)).to eq([7, 0, 0, 0])
    end

    it 'has storage output [0, 3, 3, 1]' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 3, 3, 1])
    end

    it 'has storage [7, 4, 1, 0]' do
      expect(tech.storage_curve.take(4)).to eq([7, 4, 1, 0])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 0, 0, 0])
    end
  end

  # Storage input efficiency
  # ------------------------

  context 'with alternating output [2, 0], capacity 1 and storage input efficiency 0.5' do
    let(:tech) do
      described_class.new(
        production_curve: [2.0, 0, 2.0, 0],
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 10.0, input_efficiency: 0.5 } }

    it 'has output [1, 0.5, 1, 0.5]' do
      expect(tech.output_curve.take(4)).to eq([1, 0.5, 1, 0.5])
    end

    it 'has storage input [1, 0, 1, 0]' do
      expect(tech.storage_input_curve.take(4)).to eq([1, 0, 1, 0])
    end

    it 'has storage output [0, 0.5, 0, 0.5]' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 0.5, 0, 0.5])
    end

    it 'has storage [0.5, 0, 0.5, 0]' do
      expect(tech.storage_curve.take(4)).to eq([0.5, 0, 0.5, 0])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 0, 0, 0])
    end
  end

  # Storage output efficiency
  # -------------------------

  context 'with alternating output [2, 0], capacity 1 and storage output efficiency 0.5' do
    let(:tech) do
      described_class.new(
        production_curve: [2.0, 0, 2.0, 0],
        output_capacity: 1.0,
        storage: storage
      )
    end

    let(:storage_attrs) { { volume_per_unit: 10.0, output_efficiency: 0.5 } }

    it 'has output [1, 0.5, 1, 0.5]' do
      expect(tech.output_curve.take(4)).to eq([1, 0.5, 1, 0.5])
    end

    it 'has storage input [1, 0, 1, 0]' do
      expect(tech.storage_input_curve.take(4)).to eq([1, 0, 1, 0])
    end

    it 'has storage output [0, 0.5, 0, 0.5]' do
      expect(tech.storage_output_curve.take(4)).to eq([0, 0.5, 0, 0.5])
    end

    it 'has storage [0.5, 0, 0.5, 0]' do
      expect(tech.storage_curve.take(4)).to eq([1, 0, 1, 0])
    end

    it 'has no curtailment' do
      expect(tech.curtailment_curve.take(4)).to eq([0, 0, 0, 0])
    end
  end
end
