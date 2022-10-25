# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qernel::NodeApi::EmissionsCurve do
  let(:node) do
    instance_double(Qernel::Node, dataset_attributes: {}, dataset_key: nil, dataset_group: nil)
  end

  let(:api) { Qernel::NodeApi::EnergyApi.new(node) }
  let(:result) { api.public_send(curve_name)}

  before do
    allow(api).to receive(:electricity_input_conversion).and_return(0.0)
    allow(api).to receive(:electricity_input_curve).and_return([])

    allow(api).to receive(:electricity_output_conversion).and_return(0.0)
    allow(api).to receive(:electricity_output_curve).and_return([])

    allow(api).to receive(:demand).and_return(1.0)
    allow(api).to receive(value_attribute).and_return(1000.0)
  end

  shared_examples_for 'a demand-curve based applied curve' do
    context 'when the node has non-zero electricity input' do
      before do
        allow(api).to receive(:electricity_input_conversion).and_return(1.0)
        allow(api).to receive(:electricity_input_curve).and_return([1.0, 2.0, 3.0, 4.0])
      end

      it 'has the correct emissions' do
        expect(result).to eq([100.0, 200.0, 300.0, 400.0])
      end
    end

    context 'when the node contains only zeros' do
      before do
        allow(api).to receive(:electricity_input_conversion).and_return(1.0)
        allow(api).to receive(:electricity_input_curve).and_return([0.0, 0.0, 0.0, 0.0])
      end

      it 'returns an empty curve' do
        expect(result).to eq([])
      end
    end

    context 'when the node has non-zero electricity input and no curve' do
      before do
        allow(api).to receive(:electricity_input_conversion).and_return(1.0)
      end

      it 'returns an empty curve' do
        expect(result).to eq([])
      end
    end

    context 'when the node has non-zero electricity output' do
      before do
        allow(api).to receive(:electricity_output_curve).and_return([1.0, 2.0, 3.0, 4.0])
        allow(api).to receive(:electricity_output_conversion).and_return(0.5)
      end

      it 'has the correct emissions' do
        expect(result).to eq([100.0, 200.0, 300.0, 400.0])
      end
    end

    context 'when node demand is zero' do
      before do
        allow(api).to receive(:demand).and_return(0)

        allow(api).to receive(:electricity_input_conversion).and_return(1.0)
        allow(api).to receive(:electricity_input_curve).and_return([1.0, 2.0, 3.0, 4.0])
      end

      it 'returns an empty curve' do
        expect(result).to eq([])
      end
    end
  end

  describe '#primary_co2_emissions_curve' do
    include_examples 'a demand-curve based applied curve' do
      let(:value_attribute) { :primary_co2_emission }
      let(:curve_name) { :primary_co2_emission_curve }
    end
  end

  describe '#primary_capture_of_co2_emission_curve' do
    include_examples 'a demand-curve based applied curve' do
      let(:value_attribute) { :primary_captured_co2_emission }
      let(:curve_name) { :primary_captured_co2_emission_curve }
    end
  end
end
