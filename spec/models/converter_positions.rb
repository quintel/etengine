require 'spec_helper'

describe ConverterPosition do

  describe '.all' do
    it 'should load all cps into mem' do
      expect(ConverterPosition.all).to have_at_least(1).items
    end
    it 'should return an Array' do
      expect(ConverterPosition.all).to be_a(Array)
    end

    it 'should returns ConverterPositions' do
      expect(ConverterPosition.all.first).to be_a(ConverterPosition)
    end

  end #.all

  describe '.find' do

    context 'with exisiting key' do
      it 'returns a ConverterPosition' do
        key = 'environment_sun_solar_thermal'
        expect(ConverterPosition.find(key)).to_not be_nil
        expect(ConverterPosition.find(key)).to be_a(ConverterPosition)
        expect(ConverterPosition.find(key).key).to eq key
      end
    end

    context 'with non-exisiting key' do
      it 'returns nil' do
        key = 'blah-di-blah'
        expect(ConverterPosition.find(key)).to be_nil
      end
    end

  end #.find

end
