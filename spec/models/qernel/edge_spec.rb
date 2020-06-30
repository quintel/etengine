require 'spec_helper'

module Qernel
  describe Edge do
    let(:supplier) { Node.new(key: :supplier) }
    let(:consumer) { Node.new(key: :consumer) }
    let(:carrier)  { Carrier.new(key: :network_gas) }
    let!(:edge)    { Edge.new('', consumer, supplier, carrier, :share) }

    before do
      supplier.add_slot(Slot.new('', supplier, carrier, :output))
    end

    describe '#parent_share' do
      # An other edge which belongs to the same output slot.
      let!(:other) do
        Edge.new('', consumer, supplier, carrier, :share).with(value: 15_000.0)
      end

      it 'returns a value when both edge and slot have a value' do
        edge.with(value: 5_000.0)
        expect(edge.parent_share).to eq(0.25)
      end

      it 'returns a value when edge demand is 0' do
        edge.with(value: 0.0)
        expect(edge.parent_share).to eq(0)
      end

      it 'returns a value when slot demand is 0' do
        edge.with(value: 0.0)
        other.with(value: 0.0)

        expect(edge.parent_share).to eq(0)
      end

      it 'is nil when the edge has no value' do
        # The slot demand will also be zero, since it is calculated from the
        # demands of the edges.
        edge.with(value: nil)

        expect(edge.parent_share).to be_nil
      end

      it 'computes a value when a previous attempt failed' do
        # Cannot calculate a value when a edge has no known demand...
        edge.with(value: nil)
        edge.parent_share

        # But we can now!
        edge.with(value: 5_000.0)
        expect(edge.parent_share).to be
      end
    end # parent_share

    describe "(carrier)?" do
      it 'returns true when the edge is of the correct carrier type' do
        expect(edge.network_gas?).to be_truthy
      end

      it 'returns false when the edge is of the correct carrier type' do
        expect(edge.electricity?).to be_falsey
      end

      it 'raises an error when not a valid carrier' do
        expect { edge.invalid_carrier? }.to raise_error(NoMethodError)
      end
    end # (carrier)?

    describe 'energetic?' do
      it 'returns true if the consumer node is energetic' do
        expect(consumer).to receive(:non_energetic_use?).and_return(false)
        expect(edge).to be_energetic
      end

      it 'returns false if the child node is non-energetic' do
        expect(consumer).to receive(:non_energetic_use?).and_return(true)
        expect(edge).to_not be_energetic
      end
    end # energetic?
  end # Edge
end # Qernel
