require 'spec_helper'

module Qernel
  describe Link do
    let(:supplier) { Converter.new(key: :supplier) }
    let(:consumer) { Converter.new(key: :consumer) }
    let(:carrier)  { Carrier.new(key: :network_gas) }
    let!(:link)    { Link.new('', consumer, supplier, carrier, :share) }

    describe '#parent_share' do
      # An other link which belongs to the same output slot.
      let!(:other) do
        Link.new('', consumer, supplier, carrier, :share).with(value: 15_000.0)
      end

      before do
        supplier.add_slot(Slot.new('', supplier, carrier, :output))
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
        expect(link.network_gas?).to be_true
      end

      it 'returns false when the link is of the correct carrier type' do
        expect(link.electricity?).to be_false
      end

      it 'raises an error when not a valid carrier' do
        expect { link.invalid_carrier? }.to raise_error(NoMethodError)
      end
    end # (carrier)?
  end # Link
end # Qernel
