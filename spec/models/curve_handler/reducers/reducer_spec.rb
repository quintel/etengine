# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CurveHandler::Reducers::Reducer do
  let(:scenario) { FactoryBot.create(:scenario) }

  before do
    # Write a temporary file.
    File.write(original_path, ([10.0] * 8760).join("\n")) if original_path
  end

  after do
    original_path&.unlink
  end

  describe 'when attaching a curve with a temperature reducer' do
    let(:reducer) do
      described_class.new(CurveHandler::Reducers::Temperature, '_temperature_', scenario)
    end

    let(:scenario) { FactoryBot.create(:scenario) }

    let(:original_path) do
      ds = Atlas::Dataset.find(scenario.area_code)
      ds.dataset_dir.join('curves/_temperature_.csv')
    end

    it 'returns the average temperature difference' do
      expect(reducer.call([15.0] * 8760)).to eq(5)
    end
  end

  describe 'when attaching a curve with a temperature reducer and the original does not exist' do
    let(:reducer) do
      described_class.new(CurveHandler::Reducers::Temperature, '_no_such_file_', scenario)
    end

    let(:scenario) { FactoryBot.create(:scenario) }

    # Don't save file.
    let(:original_path) { nil }

    it 'throws an error' do
      expect { reducer.call([15.0]) }.to raise_error(Errno::ENOENT)
    end
  end

  describe 'when attaching a curve belonging to a curve set with a temperature reducer' do
    let(:reducer) do
      described_class.new(CurveHandler::Reducers::Temperature, 'weather/_temperature_', scenario)
    end

    let(:scenario) { FactoryBot.create(:scenario) }

    let(:original_path) do
      ds = Atlas::Dataset.find(scenario.area_code)
      ds.dataset_dir.join('curves/weather/default/_temperature_.csv')
    end

    it 'returns the average temperature difference' do
      expect(reducer.call([15.0] * 8760)).to eq(5)
    end
  end
end
