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

  describe 'fetch' do
    let(:getter) { double('getter', call: 10.0) }

    before do
      allow(obj).to receive(:graph).and_return(
        double('graph', cache_dataset_fetch?: true)
      )
    end

    context 'with no value set' do
      it 'evaluates the block once' do
        obj.fetch(:thing) { getter.call }
        obj.fetch(:thing) { getter.call }

        expect(getter).to have_received(:call).once
      end

      it 'returns the value' do
        expect(obj.fetch(:thing) { getter.call }).to eq(10.0)
      end
    end

    context 'caching off, with no value set' do
      before do
        allow(obj).to receive(:graph).and_return(
          double('graph', cache_dataset_fetch?: false)
        )
      end

      it 'evaluates the block each time fetch is called' do
        obj.fetch(:thing) { getter.call }
        obj.fetch(:thing) { getter.call }

        expect(getter).to have_received(:call).exactly(2).times
      end

      it 'returns the value' do
        expect(obj.fetch(:thing) { getter.call }).to eq(10.0)
      end
    end

    context 'with a value already set' do
      before do
        obj.dataset_set(:thing, 20.0)
      end

      it 'does not evaluate the block' do
        obj.fetch(:thing) { getter.call }

        expect(getter).to_not have_received(:call)
      end

      it 'returns the existing value' do
        expect(obj.fetch(:thing) { getter.call }).to eq(20.0)
      end
    end
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
      context 'with "dataset_get"' do
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
      end # with "dataset_get"

      context 'with "fetch"' do
        it 'evaluates the value once' do
          obj.dataset_lazy_set(:thing) { getter.call }
          obj.fetch(:thing)
          obj.fetch(:thing)

          expect(getter).to have_received(:call).once
        end

        it 'can be retrieved by "fetch"' do
          obj.dataset_lazy_set(:thing) { getter.call }
          expect(obj.fetch(:thing)).to eq(10.0)
        end
      end # with "fetch"
    end # when retrieved
  end
end
