# frozen_string_literal: true

require 'spec_helper'

describe HeatNetworkOrder do
  it { is_expected.to have_db_index([:scenario_id, :temperature]).unique }

  describe '#order' do
    let(:preset) { described_class.new(order: order, temperature: :ht) }

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
      let(:order) { [Etsource::Config.heat_network_order_ht.first] }

      it 'has no errors' do
        preset.valid?

        expect(preset.errors[:order]).to be_empty
      end
    end

    context 'when the order contains all valid values' do
      let(:order) { Etsource::Config.heat_network_order_ht }

      it 'has no errors' do
        preset.valid?
        expect(preset.errors[:order]).to be_empty
      end
    end

    context 'when the order repeats a valid value' do
      let(:order) do
        [
          Etsource::Config.heat_network_order_ht.first,
          Etsource::Config.heat_network_order_ht.first
        ]
      end

      it 'has an error' do
        preset.valid?

        expect(preset.errors[:order]).to include(
          'contains an option more than once'
        )
      end
    end

    context 'when the order has an invalid value' do
      let(:order) { %w[invalid] }

      it 'has an error' do
        preset.valid?

        expect(preset.errors[:order]).to include(
          'contains unknown options: invalid'
        )
      end
    end
  end

  describe '#useable_order' do
    let(:fo) { described_class.new(order: order) }

    context 'when the order is empty' do
      let(:order) { [] }

      it 'returns the default order' do
        expect(fo.useable_order).to eq(described_class.default_order)
      end
    end

    describe 'when the order has all the options present' do
      let(:order) { described_class.default_order.reverse }

      it 'returns the user order' do
        expect(fo.useable_order).to eq(described_class.default_order.reverse)
      end
    end

    describe 'when the order has missing options' do
      let(:order) { [described_class.default_order.last] }

      it 'appends the missing options' do
        expect(fo.useable_order).to eq([
          described_class.default_order.last,
          *described_class.default_order[0..-2]
        ])
      end
    end

    describe 'when the order has an invalid option' do
      let(:order) { ['invalid', *described_class.default_order] }

      it 'omits the invalid option' do
        expect(fo.useable_order).to eq(described_class.default_order)
      end
    end
  end

  context 'when an order with the "ht" temperature level already exists' do
    before do
      described_class.create!(
        scenario_id: scenario.id,
        temperature: :ht
      )
    end

    let(:scenario) { FactoryBot.create(:scenario) }

    context 'with a new "ht" order' do
      let(:order) do
        described_class.new(
          scenario_id: scenario.id,
          temperature: 'ht'
        )
      end

      it 'is invalid' do
        expect(order).not_to be_valid
      end

      it 'has an error on temperature' do
        order.valid?

        expect(order.errors[:temperature])
          .to include('already exists for this scenario')
      end
    end
  end
end
