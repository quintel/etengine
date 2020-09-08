# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::MoleculeApi do
  let(:node) { FactoryBot.build(:node).with({}) }
  let(:api) { described_class.new(node) }

  let(:demand) { 0.0 }
  let(:input_capacity) { 0.0 }
  let(:output_capacity) { 0.0 }
  let(:output_of_loss) { 0.0 }

  before do
    node.with(
      demand: demand,
      typical_input_capacity: input_capacity,
      output_capacity: output_capacity
    )

    allow(api).to receive(:output_of_loss).and_return(output_of_loss)
  end

  # number_of_units
  # ---------------

  describe 'calculating number_of_units with 100 demand, 20 loss, and output capacity 0.5' do
    let(:demand) { 100.0 }
    let(:output_capacity) { 0.5 }
    let(:output_of_loss) { 20.0 }

    it 'returns 160' do
      expect(api.number_of_units).to eq(160)
    end
  end

  describe 'calculating number_of_units with 0 demand, 0 loss, and output capacity 0.5' do
    let(:demand) { 0.0 }
    let(:output_capacity) { 0.5 }
    let(:output_of_loss) { 0.0 }

    it 'returns 0' do
      expect(api.number_of_units).to eq(0)
    end
  end

  describe 'calculating number_of_units with 10 demand, 0 loss, and output capacity 0.5' do
    let(:demand) { 10.0 }
    let(:output_capacity) { 0.5 }
    let(:output_of_loss) { 0.0 }

    it 'returns 20' do
      expect(api.number_of_units).to eq(20)
    end
  end

  describe 'calculating number_of_units with 10 demand, 0 loss, and output capacity 0' do
    let(:demand) { 10.0 }
    let(:output_capacity) { 0.0 }
    let(:output_of_loss) { 0.0 }

    it 'returns 0' do
      expect(api.number_of_units).to eq(0)
    end
  end

  describe 'calculating number_of_units with 0 demand, 0 loss, and output capacity 0' do
    let(:demand) { 0.0 }
    let(:output_capacity) { 0.0 }
    let(:output_of_loss) { 0.0 }

    it 'returns 0' do
      expect(api.number_of_units).to eq(0)
    end
  end

  describe 'calculating number_of_units with 10 demand, 0 loss, and output capacity nil' do
    let(:demand) { 0.0 }
    let(:output_capacity) { nil }
    let(:output_of_loss) { 0.0 }

    it 'returns 0' do
      expect(api.number_of_units).to eq(0)
    end
  end

  describe 'calculating number_of_units with 100 demand and input capacity 5' do
    let(:demand) { 100.0 }
    let(:input_capacity) { 5.0 }

    it 'returns 20' do
      expect(api.number_of_units).to eq(20)
    end
  end

  describe 'calculating number_of_units with 100 demand and input capacity 0' do
    let(:demand) { 100.0 }
    let(:input_capacity) { 0.0 }

    it 'returns 0' do
      expect(api.number_of_units).to eq(0)
    end
  end

  describe 'calculating number_of_units with 100 demand and input capacity nil' do
    let(:demand) { 100.0 }
    let(:input_capacity) { nil }

    it 'returns 0' do
      expect(api.number_of_units).to eq(0)
    end
  end
end
