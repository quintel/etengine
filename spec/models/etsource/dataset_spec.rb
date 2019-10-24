# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Etsource::Dataset do
  describe '.weather_properties' do
    let(:properties) { described_class.weather_properties(area_code, variant) }
    let(:area_code) { :nl }

    context 'when the weather_properties.csv file exists' do
      let(:variant) { :default }

      it 'loads the properties' do
        expect(properties).to be_a(Atlas::CSVDocument)
      end
    end

    context 'when the weather_properties.csv file is missing' do
      let(:variant) { :empty }

      it 'raises an error' do
        expect { properties }.to raise_error(/No weather_properties.csv found/)
      end
    end

    context 'when the curve set variant is missing' do
      let(:variant) { :not_there }

      it 'raises an error' do
        expect { properties }.to raise_error(Atlas::MissingCurveSetVariantError)
      end
    end

    context 'when the curve set is missing' do
      let(:area_code) { :eu }
      let(:variant) { :default }

      it 'raises an error' do
        expect { properties }.to raise_error(Atlas::MissingCurveSetError)
      end
    end
  end
end
