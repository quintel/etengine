require 'spec_helper'

describe Qernel::DatasetAttributes do
  let(:obj) do
    Class.new do
      include Qernel::DatasetAttributes
      # dataset_accessor :thing

      # Not needed, but ensures correct exception message during failures.
      def dataset_key
        :id
      end
    end.new.with({})
  end

  describe 'lazy values' do
    let(:getter) { double('getter', call: 10.0) }

    context 'when set' do
      it 'does not eval the value when set' do
        obj.dataset_lazy_set(:thing) { getter.call }

        expect(getter).not_to have_received(:call)
      end

      it 'overwrites any existing value' do
        obj.dataset_set(:thing, 1.0)
        obj.dataset_lazy_set(:thing) { getter.call }

        expect(obj.dataset_get(:thing)).to eq(10.0)
      end

      it 'is overwritten by a sunsequent concrete value' do
        obj.dataset_lazy_set(:thing) { getter.call }
        obj.dataset_set(:thing, 1.0)

        expect(obj.dataset_get(:thing)).to eq(1.0)
      end
    end

    context 'when retrieved' do
      it 'evaluates the value once' do
        obj.dataset_lazy_set(:thing) { getter.call }
        obj.dataset_get(:thing)
        obj.dataset_get(:thing)

        expect(getter).to have_received(:call).once
      end

      it 'returns the value of the lambda' do
        obj.dataset_lazy_set(:thing) { getter.call }
        expect(obj.dataset_get(:thing)).to eq(10.0)
      end
    end
  end
end
