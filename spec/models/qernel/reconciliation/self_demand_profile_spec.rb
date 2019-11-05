require 'spec_helper'

describe Qernel::Reconciliation::SelfDemandProfile do
  let(:source_curve) { [5.0, 10.0, 15.0, 10.0, 10.0] }

  let(:converter) do
    carrier = Qernel::Carrier.new(key: :valid)
    converter = Qernel::Converter.new(key: :fake_converter).with(demand: 100.0)

    converter.add_slot(Qernel::Slot.factory(nil, 0, nil, carrier, :input))
    converter.add_slot(Qernel::Slot.factory(nil, 1, nil, carrier, :output))

    converter
  end

  let(:result) do |example|
    description = example.metadata[:example_group][:description]
    match = description.match(/"([^"]*)"/)

    unless match
      raise "Cannot parse curve name in from example: #{description.inspect}"
    end

    described_class.build(converter, match[1])
  end

  shared_examples_for 'a valid demand profile name' do
    it 'returns an array' do
      expect(result).to be_a(Array)
    end

    it 'has as many elements as the source curve' do
      expect(result.length).to eq(5)
    end

    it 'is based on the values in the source curve and slot conversion' do
      expect(result).to eq([0.1, 0.2, 0.3, 0.2, 0.2].map { |v| v / 3600 })
    end
  end

  context 'when using "valid_input_curve"' do
    before do
      allow(converter.input(:valid)).to receive(:conversion).and_return(0.5)
      allow(converter.query)
        .to receive(:valid_input_curve).and_return(source_curve)
    end

    include_examples 'a valid demand profile name'
  end

  context 'when using "valid_output_curve"' do
    before do
      allow(converter.output(:valid)).to receive(:conversion).and_return(0.5)
      allow(converter.query)
        .to receive(:valid_output_curve).and_return(source_curve)
    end

    include_examples 'a valid demand profile name'
  end

  context 'when using "valid_output_curve "' do
    before do
      allow(converter.output(:valid)).to receive(:conversion).and_return(0.5)
      allow(converter.query)
        .to receive(:valid_output_curve).and_return(source_curve)
    end

    include_examples 'a valid demand profile name'
  end

  context 'when using "valid_underscored_output_curve "' do
    before do
      allow(converter.output(:valid)).to receive(:conversion).and_return(0.5)
      allow(converter.query)
        .to receive(:valid_underscored_output_curve).and_return(source_curve)
    end

    include_examples 'a valid demand profile name'
  end

  context 'when using "valid_output_curve" and no curve is set' do
    before do
      allow(converter.output(:valid)).to receive(:conversion).and_return(0.5)
      allow(converter.query).to receive(:valid_output_curve).and_return(nil)
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
      allow(converter.output(:valid)).to receive(:conversion).and_return(0.5)
      allow(converter.query).to receive(:valid_output_curve).and_return([])
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
          No such curve attribute ""; was specified by converter fake_converter
          to create a profile for "self:"
        MESSAGE
      )
    end
  end
end
