require 'spec_helper'

module Qernel
  describe Link do
    let(:supplier) { Node.new(key: :supplier) }
    let(:consumer) { Node.new(key: :consumer) }
    let(:carrier)  { Carrier.new(key: :network_gas) }
    let!(:link)    { Link.new('', consumer, supplier, carrier, :share) }

    before do
      supplier.add_slot(Slot.new('', supplier, carrier, :output))
    end

    describe '#parent_share' do
      # An other link which belongs to the same output slot.
      let!(:other) do
        Link.new('', consumer, supplier, carrier, :share).with(value: 15_000.0)
      end

      it 'returns a value when both link and slot have a value' do
        link.with(value: 5_000.0)
        expect(link.parent_share).to eq(0.25)
      end

      it 'returns a value when link demand is 0' do
        link.with(value: 0.0)
        expect(link.parent_share).to eq(0)
      end

      it 'returns a value when slot demand is 0' do
        link.with(value: 0.0)
        other.with(value: 0.0)

        expect(link.parent_share).to eq(0)
      end

      it 'is nil when the link has no value' do
        # The slot demand will also be zero, since it is calculated from the
        # demands of the links.
        link.with(value: nil)

        expect(link.parent_share).to be_nil
      end

      it 'computes a value when a previous attempt failed' do
        # Cannot calculate a value when a link has no known demand...
        link.with(value: nil)
        link.parent_share

        # But we can now!
        link.with(value: 5_000.0)
        expect(link.parent_share).to be
      end
    end # parent_share

    describe "(carrier)?" do
      it 'returns true when the link is of the correct carrier type' do
        expect(link.network_gas?).to be_truthy
      end

      it 'returns false when the link is of the correct carrier type' do
        expect(link.electricity?).to be_falsey
      end

      it 'raises an error when not a valid carrier' do
        expect { link.invalid_carrier? }.to raise_error(NoMethodError)
      end
    end # (carrier)?

    describe 'primary_demand' do
      it 'returns the right node value, minus conversions' do
        expect(supplier).to receive(:primary_demand).and_return(40.0)
        expect(supplier).to receive(:loss_compensation_factor).and_return(1.0)
        expect(link.output).to receive(:conversion).and_return(0.5)
        expect(link).to receive(:parent_share).and_return(0.25)

        expect(link.primary_demand).to eq(5.0)
      end

      it 'returns the right node value, minus conversions adjusting for loss' do
        expect(supplier).to receive(:primary_demand).and_return(40.0)
        expect(supplier).to receive(:loss_compensation_factor).and_return(1.5)
        expect(link.output).to receive(:conversion).and_return(0.5)
        expect(link).to receive(:parent_share).and_return(0.25)

        expect(link.primary_demand).to eq(7.5)
      end

      it 'returns nil if the parent node value is nil' do
        expect(supplier).to receive(:primary_demand).and_return(nil)
        expect(link.primary_demand).to be_nil
      end
    end # primary_demand

    describe 'primary_demand_of_carrier' do
      it 'returns the right node value, minus conversions' do
        expect(supplier).to receive(:primary_demand_of_carrier).
          with(:coal).and_return(40.0)

        expect(supplier).to receive(:loss_compensation_factor).and_return(1.0)
        expect(link.output).to receive(:conversion).and_return(0.5)
        expect(link).to receive(:parent_share).and_return(0.25)

        expect(link.primary_demand_of_carrier(:coal)).to eq(5.0)
      end

      it 'returns nil if the parent node value is nil' do
        expect(supplier).to receive(:primary_demand_of_carrier).
          with(:coal).and_return(nil)

        expect(link.primary_demand_of_carrier(:coal)).to be_nil
      end
    end # primary_demand_of_carrier

    describe 'sustainability_share' do
      it 'returns the right node value, minus conversions' do
        expect(supplier).to receive(:sustainability_share).and_return(0.5)

        expect(supplier).not_to receive(:loss_compensation_factor)
        expect(link.output).to receive(:conversion).and_return(0.5)
        expect(link).to receive(:parent_share).and_return(0.25)

        expect(link.sustainability_share).to eq(0.5 * 0.5 * 0.25)
      end
    end # sustainability_share

    describe 'energetic?' do
      it 'returns true if the consumer node is energetic' do
        expect(consumer).to receive(:non_energetic_use?).and_return(false)
        expect(link).to be_energetic
      end

      it 'returns false if the child node is non-energetic' do
        expect(consumer).to receive(:non_energetic_use?).and_return(true)
        expect(link).to_not be_energetic
      end
    end # energetic?
  end # Link
end # Qernel
