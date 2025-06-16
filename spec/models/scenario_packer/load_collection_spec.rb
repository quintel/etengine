# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ScenarioPacker::LoadCollection do
  describe '.from_file' do
    let(:file) { Tempfile.new('dump.json') }

    after { file.close! }

    context 'when file does not respond to path' do
      it 'raises ArgumentError' do
        fake = double('File')
        expect { described_class.from_file(fake) }
          .to raise_error(ArgumentError, /No file provided/)
      end
    end

    context 'when file has JSON object' do
      let(:scenario1) { double('Scenario', id: 10) }

      before do
        file.write({ foo: 'bar' }.to_json)
        file.rewind

        loader = double('Load', scenario: scenario1)
        allow(ScenarioPacker::Load).to receive(:new).and_return(loader)
      end

      it 'loads one scenario and returns loader' do
        result = described_class.from_file(file)

        expect(result).to be_a(described_class)
        expect(result.scenarios).to eq([scenario1])
        expect(result.first_id).to eq(10)
        expect(result.single?).to be(true)
      end
    end

    context 'when file has JSON array' do
      let(:scenario1) { double('Scenario', id: 1) }
      let(:scenario2) { double('Scenario', id: 2) }

      before do
        file.write([{ foo: 'a' }, { foo: 'b' }].to_json)
        file.rewind

        loaders = [
          double('Load', scenario: scenario1),
          double('Load', scenario: scenario2)
        ]

        allow(ScenarioPacker::Load)
          .to receive(:new)
          .and_return(*loaders)
      end

      it 'loads multiple scenarios correctly' do
        result = described_class.from_file(file)

        aggregate_failures do
          expect(result.scenarios).to eq([scenario1, scenario2])
          expect(result.first_id).to eq(1)
          expect(result.single?).to be(false)
        end
      end
    end
  end

  describe '#load_all' do
    subject(:collection) { described_class.new(data) }

    let(:data)      { [{}, {}] }
    let(:scenarios) { [double('Scenario1'), double('Scenario2')] }
    let(:loaders)   { scenarios.map { |s| double('Load', scenario: s) } }

    it 'populates scenarios via Load in order' do
      allow(ScenarioPacker::Load).to receive(:new).and_return(*loaders)
      collection.load_all
      expect(collection.scenarios).to eq(scenarios)
    end
  end
end
