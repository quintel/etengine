# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CurveHandler::Config do
  let(:config) { described_class.new(key, processor_key, reducer_key, input_keys) }

  let(:key) { :unique_key }
  let(:processor_key) { :generic }
  let(:reducer_key) { nil }
  let(:input_keys) { [] }

  context 'when given processor_key=:price' do
    let(:processor_key) { :price }

    it 'uses the Price processor' do
      expect(config.processor).to eq(CurveHandler::Processors::Price)
    end

    it 'sets no inputs' do
      expect(config.sets_inputs?).to be(false)
    end

    it 'has no reducer' do
      expect(config.reducer).to be(nil)
    end
  end

  context 'when given processor_key=:profile' do
    let(:processor_key) { :profile }

    it 'uses the Profile processor' do
      expect(config.processor).to eq(CurveHandler::Processors::Profile)
    end
  end

  context 'when given processor_key=:generic and reducer=:full_load_hours' do
    let(:processor_key) { :generic }
    let(:reducer_key) { :full_load_hours }

    it 'uses the Generic processor' do
      expect(config.processor).to eq(CurveHandler::Processors::Generic)
    end

    it 'sets no inputs' do
      expect(config.sets_inputs?).to be(false)
    end

    it 'has no reducer' do
      expect(config.reducer).to be_nil
    end
  end

  context 'when given processor_key=:generic and reducer=:full_load_hours and input_keys=%i[a b]' do
    let(:processor_key) { :generic }
    let(:reducer_key) { :full_load_hours }
    let(:input_keys)  { %i[a b] }

    it 'uses the Generic processor' do
      expect(config.processor).to eq(CurveHandler::Processors::Generic)
    end

    it 'sets inputs' do
      expect(config.sets_inputs?).to be(true)
    end

    it 'uses the FullLoadHours reducer' do
      expect(config.reducer).to be(CurveHandler::Reducers::FullLoadHours)
    end
  end

  context 'when no key is given' do
    let(:key) { nil }

    it 'raises an error when creating the config' do
      expect { config }.to raise_error(/cannot create .+ without a key/i)
    end
  end

  context 'when given processor_key=nil' do
    let(:processor_key) { nil }

    it 'raises an error when creating the config' do
      expect { config }.to raise_error(/cannot create .+ without a processor/i)
    end
  end

  context 'when given processor_key=:invalid' do
    let(:processor_key) { :invalid }

    it 'raises an error when fetching the processor' do
      expect { config.processor }.to raise_error(/unknown processor/i)
    end
  end

  context 'when given reducer_key=nil' do
    let(:reducer_key) { nil }

    it 'has no reducer' do
      expect(config.reducer).to be_nil
    end
  end

  context 'when given reducer_key=:invalid and some input keys' do
    let(:reducer_key) { :invalid }
    let(:input_keys) { %w[a b] }

    it 'raises an error when fetching the reducer' do
      expect { config.reducer }.to raise_error(/unknown reducer/i)
    end
  end

  describe '.from_etsource' do
    let(:config) { described_class.from_etsource(config_hash) }

    context 'with a simple config hash' do
      let(:config_hash) do
        { key: :my_curve, type: :generic }
      end

      it 'sets the key' do
        expect(config.key).to eq(:my_curve)
      end

      it 'sets the processor' do
        expect(config.processor).to eq(CurveHandler::Processors::Generic)
      end

      it 'will set no inputs' do
        expect(config.sets_inputs?).to be(false)
      end
    end

    context 'with a reducer config hash and a string input' do
      let(:config_hash) do
        { key: :my_curve, type: :generic, reduce: { as: :full_load_hours, sets: :my_input } }
      end

      it 'sets the key' do
        expect(config.key).to eq(:my_curve)
      end

      it 'sets the processor' do
        expect(config.processor).to eq(CurveHandler::Processors::Generic)
      end

      it 'will reduce a value to inputs' do
        expect(config.sets_inputs?).to be(true)
      end

      it 'sets the reducer' do
        expect(config.reducer).to eq(CurveHandler::Reducers::FullLoadHours)
      end

      it 'sets input keys' do
        expect(config.input_keys).to eq(['my_input'])
      end
    end

    context 'with a reducer config hash and an array of Symbol inputs' do
      let(:config_hash) do
        {
          key: :my_curve,
          type: :generic,
          reduce: { as: :full_load_hours, sets: %i[input_one input_two] }
        }
      end

      it 'sets the key' do
        expect(config.key).to eq(:my_curve)
      end

      it 'sets the processor' do
        expect(config.processor).to eq(CurveHandler::Processors::Generic)
      end

      it 'will reduce a value to inputs' do
        expect(config.sets_inputs?).to be(true)
      end

      it 'sets the reducer' do
        expect(config.reducer).to eq(CurveHandler::Reducers::FullLoadHours)
      end

      it 'sets input keys as Strings' do
        expect(config.input_keys).to eq(%w[input_one input_two])
      end
    end

    context 'with a reducer config hash and an array of String inputs' do
      let(:config_hash) do
        {
          key: :my_curve,
          type: :generic,
          reduce: { as: :full_load_hours, sets: %w[input_one input_two] }
        }
      end

      it 'sets input keys as Strings' do
        expect(config.input_keys).to eq(%w[input_one input_two])
      end
    end
  end
end
