require 'spec_helper'

module Qernel
  describe Link do
    describe '#parent_share' do
      let(:supplier) { Converter.new(key: :supplier) }
      let(:consumer) { Converter.new(key: :consumer) }
      let(:carrier)  { Carrier.new(key: :gas) }
      let!(:link)    { Link.new('', consumer, supplier, carrier, :share) }

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
  end # Link
end # Qernel
