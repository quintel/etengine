# frozen_string_literal: true

require 'spec_helper'

describe FlexibilityOrder do
  it { is_expected.to validate_uniqueness_of(:scenario_id) }

  describe '#order' do
    let(:preset) { described_class.new(order: order) }

    context 'when the order is nil' do
      let(:order) { nil }

      it 'has no errors' do
        expect(preset.errors[:order]).to be_empty
      end
    end

    context 'when the order is an empty array' do
      let(:order) { [] }

      it 'has no errors' do
        preset.valid?
        expect(preset.errors[:order]).to be_empty
      end
    end

    context 'when the order contains one of two valid values' do
      let(:order) { [Etsource::Config.flexibility_order.first] }

      it 'has no errors' do
        preset.valid?

        expect(preset.errors[:order]).to be_empty
      end
    end

    context 'when the order contains all valid values' do
      let(:order) { Etsource::Config.flexibility_order }

      it 'has no errors' do
        preset.valid?
        expect(preset.errors[:order]).to be_empty
      end
    end

    context 'when the order repeats a valid value' do
      let(:order) do
        [
          Etsource::Config.flexibility_order.first,
          Etsource::Config.flexibility_order.first
        ]
      end

      it 'has an error' do
        preset.valid?

        expect(preset.errors[:order]).to include(
          'contains a flexibility option more than once'
        )
      end
    end

    context 'when the order has an invalid value' do
      let(:order) { %w[invalid] }

      it 'has an error' do
        preset.valid?

        expect(preset.errors[:order]).to include(
          'contains unknown flexibility options: invalid'
        )
      end
    end
  end
end
