require 'spec_helper'

module Qernel
  describe Slot do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    describe '.factory' do
      let(:node) { Qernel::Node.new(id: 1) }

      context 'when type=nil' do
        it 'should be an ordinary slot' do
          slot = Qernel::Slot.factory(
            nil, 1, node,
            Qernel::Carrier.new(key: :electricity), :output)

          expect(slot).to     be_a(Qernel::Slot)
          expect(slot).not_to be_a(Qernel::Slot::Elastic)
        end
      end

      context 'when type=invalid' do
        it 'should be an ordinary slot' do
          slot = Qernel::Slot.factory(:invalid,
            1, node, Qernel::Carrier.new(key: :loss), :input)

          expect(slot).to     be_a(Qernel::Slot)
          expect(slot).not_to be_a(Qernel::Slot::Elastic)
        end
      end

      context 'when type=elastic' do
        it 'should be an elastic slot' do
          slot = Qernel::Slot.factory(:elastic,
            1, node, Qernel::Carrier.new(key: :loss), :output)

          expect(slot).to be_a(Qernel::Slot::Elastic)
        end
      end

    end
  end
end
