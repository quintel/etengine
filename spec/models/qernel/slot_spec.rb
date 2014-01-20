require 'spec_helper'

module Qernel
  describe Slot do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    describe '.factory' do
      let(:converter) { Qernel::Converter.new(id: 1) }

      context 'when type=nil' do
        it 'should be an ordinary slot' do
          slot = Qernel::Slot.factory(
            nil, 1, converter,
            Qernel::Carrier.new(key: :electricity), :output)

          slot.should     be_a(Qernel::Slot)
          slot.should_not be_a(Qernel::Slot::Elastic)
        end
      end

      context 'when type=invalid' do
        it 'should be an ordinary slot' do
          slot = Qernel::Slot.factory(:invalid,
            1, converter, Qernel::Carrier.new(key: :loss), :input)

          slot.should     be_a(Qernel::Slot)
          slot.should_not be_a(Qernel::Slot::Elastic)
        end
      end

      context 'when type=elastic' do
        it 'should be an elastic slot' do
          slot = Qernel::Slot.factory(:elastic,
            1, converter, Qernel::Carrier.new(key: :loss), :output)

          slot.should be_a(Qernel::Slot::Elastic)
        end
      end

    end
  end
end
