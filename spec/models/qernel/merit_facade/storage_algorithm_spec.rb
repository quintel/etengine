# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::MeritFacade::StorageAlgorithm do
  describe '#run' do
    context 'with [10000, ..., 5000, ...], capacity 1000, volume 10000' do
      let(:reserve) do
        described_class.run(
          ([10_000] * 6 + [5000] * 6) * 365,
          capacity: 1000,
          volume: 10_000
        )
      end

      it 'calcualtes the stored energy, limited by capacity' do
        expect(reserve.to_a[24...36]).to eq(
          [5000, 4000, 3000, 2000, 1000, 0, 1000, 2000, 3000, 4000, 5000, 6000]
        )
      end
    end

    context 'with [10000, ..., 5000, ...], capacity 100, volume 1000' do
      let(:reserve) do
        described_class.run(
          ([10_000] * 6 + [5000] * 6) * 365,
          capacity: 100,
          volume: 1000
        )
      end

      it 'calcualtes the stored energy, limited by capacity' do
        expect(reserve.to_a[24...36]).to eq(
          [500, 400, 300, 200, 100, 0, 100, 200, 300, 400, 500, 600]
        )
      end
    end

    context 'with [10000, ..., 5000, ...], capacity 100, volume 300' do
      let(:reserve) do
        described_class.run(
          ([10_000] * 6 + [5000] * 6) * 365,
          capacity: 100,
          volume: 300
        )
      end

      it 'calcualtes the stored energy, limited by volume' do
        expect(reserve.to_a[24...36]).to eq(
          [300, 300, 300, 200, 100, 0, 0, 0, 0, 100, 200, 300]
        )
      end
    end
  end
end
