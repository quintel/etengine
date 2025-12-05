# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioPacker::LoadCollection do
  describe '.from_file' do
    let(:file) { Tempfile.new('dump.json') }

    after { file.close! }

    context 'when file does not respond to path' do
      it 'returns a failure' do
        fake = double('File')
        result = described_class.from_file(fake)
        expect(result).to be_failure
        expect(result.failure.to_s).to match(/must be an uploaded file/)
      end
    end

    context 'when file has JSON object' do
      let(:scenario1) { double('Scenario', id: 10) }

      before do
        file.write({ foo: 'bar' }.to_json)
        file.rewind

        loader = double('Load')
        allow(loader).to receive(:call).and_return(Dry::Monads::Success(scenario1))
        allow(ScenarioPacker::Load).to receive(:new).and_return(loader)
      end

      it 'loads one scenario and returns loader' do
        result = described_class.from_file(file)
        expect(result).to be_success

        load_result = result.value!
        expect(load_result.scenarios).to eq([scenario1])
        expect(load_result.first_id).to eq(10)
        expect(load_result.single?).to be(true)
      end
    end

    context 'when file has JSON array' do
      let(:scenario1) { double('Scenario', id: 1) }
      let(:scenario2) { double('Scenario', id: 2) }

      before do
        file.write([{ foo: 'a' }, { foo: 'b' }].to_json)
        file.rewind

        loaders = [
          double('Load').tap { |l| allow(l).to receive(:call).and_return(Dry::Monads::Success(scenario1)) },
          double('Load').tap { |l| allow(l).to receive(:call).and_return(Dry::Monads::Success(scenario2)) }
        ]

        allow(ScenarioPacker::Load)
          .to receive(:new)
          .and_return(*loaders)
      end

      it 'loads multiple scenarios correctly' do
        result = described_class.from_file(file)
        expect(result).to be_success

        load_result = result.value!
        aggregate_failures do
          expect(load_result.scenarios).to eq([scenario1, scenario2])
          expect(load_result.first_id).to eq(1)
          expect(load_result.single?).to be(false)
        end
      end
    end
  end

  describe '#call' do
    subject(:collection) { described_class.new(data) }

    let(:data)      { [{}, {}] }
    let(:scenarios) { [double('Scenario1'), double('Scenario2')] }
    let(:loaders)   do
      scenarios.map do |s|
        double('Load').tap { |l| allow(l).to receive(:call).and_return(Dry::Monads::Success(s)) }
      end
    end

    it 'populates scenarios via Load in order' do
      allow(ScenarioPacker::Load).to receive(:new).and_return(*loaders)
      result = collection.call
      expect(result).to be_success
      expect(result.value!.scenarios).to eq(scenarios)
    end
  end
end
