# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::Closud::Queryable do
  let(:transform) { described_class::DEFAULT_TRANSFORM }

  let(:queryable) do
    described_class.new(OpenStruct.new(lv: layer), transform)
  end

  context 'with an :lv layer' do
    let(:base)   { Struct.new(:load_curve).new(Merit::Curve.new([0, 0, 0, 0])) }
    let(:supply) { [1, 2, 3, 4] }
    let(:demand) { [2, 4, 6, 8] }

    let(:layer) do
      Qernel::Closud::Layer.new(
        base: base,
        consumers: [Merit::Curve.new(demand)],
        producers: [Merit::Curve.new(supply)]
      )
    end

    it 'returns curves as arrays' do
      expect(queryable.load_curve(:lv)).to be_a(Array)
    end

    it 'fetches the lv load curve' do
      expect(queryable.load_curve(:lv).to_a).to eq([1, 2, 3, 4])
    end

    it 'fetches the lv demand curve' do
      expect(queryable.demand_curve(:lv).to_a).to eq([2, 4, 6, 8])
    end

    it 'fetches the lv supply curve' do
      expect(queryable.supply_curve(:lv).to_a).to eq([1, 2, 3, 4])
    end

    it 'fetches the lv peak load' do
      expect(queryable.peak_load(:lv)).to eq(4)
    end

    context 'with a curve transform, rotating by half' do
      let(:transform) { ->(curve) { curve.rotate(curve.length / 2) } }

      it 'transforms the lv load curve' do
        expect(queryable.load_curve(:lv).to_a).to eq([3, 4, 1, 2])
      end

      it 'transforms the lv demand curve' do
        expect(queryable.demand_curve(:lv).to_a).to eq([6, 8, 2, 4])
      end

      it 'transforms the lv supply curve' do
        expect(queryable.supply_curve(:lv).to_a).to eq([3, 4, 1, 2])
      end
    end
  end

  context 'with a non-existent layer' do
    let(:layer) do
      Qernel::Closud::Layer.new(
        consumers: [],
        producers: [],
        flexibles: []
      )
    end

    it 'raises an error fetching the load curve' do
      expect { queryable.load_curve(:no) }
        .to raise_error(/No such network layer/)
    end

    it 'raises an error fetching the demand curve' do
      expect { queryable.demand_curve(:no) }
        .to raise_error(/No such network layer/)
    end

    it 'raises an error fetching the supply curve' do
      expect { queryable.supply_curve(:no) }
        .to raise_error(/No such network layer/)
    end

    it 'raises an error fetching the peak load' do
      expect { queryable.peak_load(:no) }
        .to raise_error(/No such network layer/)
    end
  end
end
