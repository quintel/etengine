require 'spec_helper'

module Qernel::Closud
  RSpec.describe Layer do
    let(:consumers) { [] }
    let(:producers) { [] }
    let(:flexibles) { [] }
    let(:base) { nil }

    let(:layer) do
      Layer.new(
        consumers: consumers,
        producers: producers,
        flexibles: flexibles,
        base: base
      )
    end

    context 'with no base, consumers, or producers' do
      it 'has a load curve with 8760 entries' do
        expect(layer.load_curve.length).to eq(8760)
      end

      it 'has no load' do
        expect(layer.load_curve.sum).to be_zero
      end
    end

    context 'with a constant base 1.0, and no consumers or producers' do
      let(:base) do
        double('Base Layer', load_curve: Merit::Curve.new([], 8760, 1.0))
      end

      it 'has a load curve with 8760 entries' do
        expect(layer.load_curve.length).to eq(8760)
      end

      it 'has constant load of 1.0' do
        expect(layer.load_curve.all? { |v| v == 1.0 }).to be(true)
      end

      it 'has a constant supply curve of 0.0' do
        expect(layer.supply_curve.all? { |v| v == 0.0 }).to be(true)
      end

      it 'has a constant demand curve of 1.0' do
        expect(layer.demand_curve.all? { |v| v == 1.0 }).to be(true)
      end
    end

    context 'with a constant base 1.0, constant consumer 1.0, and no producers' do
      let(:base) do
        double('Base Layer', load_curve: Merit::Curve.new([], 8760, 1.0))
      end

      let(:consumers) do
        [Merit::Curve.new([], 8760, 1.0)]
      end

      it 'has a load curve with 8760 entries' do
        expect(layer.load_curve.length).to eq(8760)
      end

      it 'has constant load of 2.0' do
        expect(layer.load_curve.all? { |v| v == 2.0 }).to be(true)
      end

      it 'has a constant supply curve of 0.0' do
        expect(layer.supply_curve.all? { |v| v == 0.0 }).to be(true)
      end

      it 'has a constant demand curve of 2.0' do
        expect(layer.demand_curve.all? { |v| v == 2.0 }).to be(true)
      end
    end

    context 'with a constant base -1.0, constant consumer 1.0, and no producers' do
      let(:base) do
        double('Base Layer', load_curve: Merit::Curve.new([], 8760, -1.0))
      end

      let(:consumers) do
        [Merit::Curve.new([], 8760, 1.0)]
      end

      it 'has a load curve with 8760 entries' do
        expect(layer.load_curve.length).to eq(8760)
      end

      it 'has constant load of 0.0' do
        expect(layer.load_curve.all? { |v| v == 0.0 }).to be(true)
      end

      it 'has a constant supply curve of 1.0' do
        expect(layer.supply_curve.all? { |v| v == 1.0 }).to be(true)
      end

      it 'has a constant demand curve of 1.0' do
        expect(layer.demand_curve.all? { |v| v == 1.0 }).to be(true)
      end
    end

    context 'with a constant base 1.0, constant consumer 1.0, constant producer 2.0' do
      let(:base) do
        double('Base Layer', load_curve: Merit::Curve.new([], 8760, 1.0))
      end

      let(:consumers) { [Merit::Curve.new([], 8760, 1.0)] }
      let(:producers) { [Merit::Curve.new([], 8760, 2.0)] }

      it 'has a load curve with 8760 entries' do
        expect(layer.load_curve.length).to eq(8760)
      end

      it 'has constant load of 0.0' do
        expect(layer.load_curve.all? { |v| v == 0.0 }).to be(true)
      end

      it 'has a constant supply curve of 2.0' do
        expect(layer.supply_curve.all? { |v| v == 2.0 }).to be(true)
      end

      it 'has a constant demand curve of 2.0' do
        expect(layer.demand_curve.all? { |v| v == 2.0 }).to be(true)
      end
    end

    context 'with no base, constant consumer 1.0, constant producer 2.0, constant flex 1.0' do
      let(:consumers) { [Merit::Curve.new([], 8760, 1.0)] }
      let(:producers) { [Merit::Curve.new([], 8760, 2.0)] }
      let(:flexibles) { [Merit::Curve.new([], 8760, 1.0)] }

      it 'has a load curve with 8760 entries' do
        expect(layer.load_curve.length).to eq(8760)
      end

      # +1 consumption, -2 production, -1 flex
      it 'has constant load of -2.0' do
        expect(layer.load_curve.all? { |v| v == -2.0 }).to be(true)
      end

      it 'has a constant supply curve of 3.0' do
        expect(layer.supply_curve.all? { |v| v == 3.0 }).to be(true)
      end

      it 'has a constant demand curve of 1.0' do
        expect(layer.demand_curve.all? { |v| v == 1.0 }).to be(true)
      end
    end

    context 'with no base, constant consumer 1.0, constant producer 2.0, constant flex -1.0' do
      let(:consumers) { [Merit::Curve.new([], 8760, 1.0)] }
      let(:producers) { [Merit::Curve.new([], 8760, 2.0)] }
      let(:flexibles) { [Merit::Curve.new([], 8760, -1.0)] }

      it 'has a load curve with 8760 entries' do
        expect(layer.load_curve.length).to eq(8760)
      end

      # +1 consumption, -2 production, +1 flex
      it 'has constant load of -2.0' do
        expect(layer.load_curve.all? { |v| v == 0.0 }).to be(true)
      end

      it 'has a constant supply curve of 2.0' do
        expect(layer.supply_curve.all? { |v| v == 2.0 }).to be(true)
      end

      it 'has a constant demand curve of 2.0' do
        expect(layer.demand_curve.all? { |v| v == 2.0 }).to be(true)
      end
    end
  end

end
