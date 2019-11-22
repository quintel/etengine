# frozen_string_literal: true

require 'spec_helper'

describe Qernel::Causality::SelfDemandProfile do
  def curve_name_from_example(example)
    description = example.metadata[:example_group][:description]
    match = description.match(/"([^"]*)"/)

    unless match
      raise "Cannot parse curve name in from example: #{description.inspect}"
    end

    match[1]
  end

  let(:source_curve) { [5.0, 10.0, 15.0, 10.0, 10.0] }

  let(:converter) do
    Qernel::Converter.new(key: :fake_converter).with(demand: 100.0).converter_api
  end

  describe '.curve' do
    let(:result) do |example|
      described_class.curve(converter, curve_name_from_example(example))
    end

    shared_examples_for 'a valid demand curve name' do
      it 'returns an array' do
        expect(result).to be_a(Array)
      end

      it 'has as many elements as the source curve' do
        expect(result.length).to eq(5)
      end

      it 'returns the source curve' do
        expect(result).to eq(source_curve)
      end
    end

    context 'when using "valid_input_curve"' do
      before do
        allow(converter).to receive(:valid_input_curve).and_return(source_curve)
      end

      include_examples 'a valid demand curve name'
    end

    context 'when using "valid_output_curve"' do
      before do
        allow(converter)
          .to receive(:valid_output_curve).and_return(source_curve)
      end

      include_examples 'a valid demand curve name'
    end

    context 'when using "valid_output_curve "' do
      before do
        allow(converter)
          .to receive(:valid_output_curve).and_return(source_curve)
      end

      include_examples 'a valid demand curve name'
    end

    context 'when using "valid_underscored_output_curve "' do
      before do
        allow(converter)
          .to receive(:valid_underscored_output_curve).and_return(source_curve)
      end

      include_examples 'a valid demand curve name'
    end

    context 'when using "valid_output_curve" and no curve is set' do
      before do
        allow(converter).to receive(:valid_output_curve).and_return(nil)
      end

      it 'raises an error' do
        expect { result }.to raise_error(
          <<~MESSAGE.squish
            Converter fake_converter does not have a "valid_output_curve" to use
            as profile "self: valid_output_curve"
          MESSAGE
        )
      end
    end

    context 'when using "valid_output_curve" and an empty curve is set' do
      before do
        allow(converter).to receive(:valid_output_curve).and_return([])
      end

      it 'raises an error' do
        expect { result }.to raise_error(
          <<~MESSAGE.squish
            Converter fake_converter does not have a "valid_output_curve" to use
            as profile "self: valid_output_curve"
          MESSAGE
        )
      end
    end

    context 'when using "invalid_input_curve"' do
      it 'raises an error' do
        expect { result }.to raise_error(
          <<~MESSAGE.squish
            No such curve attribute "invalid_input_curve"; was specified by
            converter fake_converter to create a profile for
            "self: invalid_input_curve"
          MESSAGE
        )
      end
    end

    context 'when using "invalid_input"' do
      it 'raises an error' do
        expect { result }.to raise_error(
          <<~MESSAGE.squish
            No such curve attribute "invalid_input"; was specified by converter
            fake_converter to create a profile for "self: invalid_input"
          MESSAGE
        )
      end
    end

    context 'when using "invalid_nothing_curve"' do
      it 'raises an error' do
        expect { result }.to raise_error(
          <<~MESSAGE.squish
            No such curve attribute "invalid_nothing_curve"; was specified by
            converter fake_converter to create a profile for
            "self: invalid_nothing_curve"
          MESSAGE
        )
      end
    end

    context 'when using "to_s"' do
      it 'raises an error' do
        expect { result }.to raise_error(
          <<~MESSAGE.squish
            No such curve attribute "to_s"; was specified by converter
            fake_converter to create a profile for "self: to_s"
          MESSAGE
        )
      end
    end

    context 'when using ""' do
      it 'raises an error' do
        expect { result }.to raise_error(
          <<~MESSAGE.squish
            No such curve attribute ""; was specified by converter
            fake_converter to create a profile for "self:"
          MESSAGE
        )
      end
    end
  end

  describe '.profile' do
    let(:result) do
      described_class.profile(converter, 'valid_input_curve')
    end

    before do
      allow(converter)
        .to receive(:valid_input_curve).and_return(source_curve)
    end

    it 'returns an array' do
      expect(result).to be_a(Array)
    end

    it 'has as many elements as the source curve' do
      expect(result.length).to eq(5)
    end

    it 'converts the demand curve to a MJ->MWh profile' do
      expect(result).to eq([0.1, 0.2, 0.3, 0.2, 0.2].map { |v| v / 3600 })
    end
  end

  describe '.decode_name' do
    let(:result) do |example|
      described_class.decode_name(curve_name_from_example(example))
    end

    context 'with "valid_input_curve"' do
      it 'has a carrier of :valid' do
        expect(result[:carrier]).to eq(:valid)
      end

      it 'has a direction of :input' do
        expect(result[:direction]).to eq(:input)
      end
    end

    context 'with "valid_output_curve"' do
      it 'has a carrier of :valid' do
        expect(result[:carrier]).to eq(:valid)
      end

      it 'has a direction of :output' do
        expect(result[:direction]).to eq(:output)
      end
    end

    context 'with "valid_thing_input_curve"' do
      it 'has a carrier of :valid_thing' do
        expect(result[:carrier]).to eq(:valid_thing)
      end

      it 'has a direction of :input' do
        expect(result[:direction]).to eq(:input)
      end
    end

    context 'with "self: valid_input_curve"' do
      it 'has a carrier of :valid' do
        expect(result[:carrier]).to eq(:valid)
      end

      it 'has a direction of :input' do
        expect(result[:direction]).to eq(:input)
      end
    end

    context 'with "self-thing: valid_input_curve"' do
      it 'has a carrier of :valid' do
        expect(result[:carrier]).to eq(:valid)
      end

      it 'has a direction of :input' do
        expect(result[:direction]).to eq(:input)
      end
    end

    context 'with "valid_noput_curve"' do
      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'with "valid_output"' do
      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'with ""' do
      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end
end
