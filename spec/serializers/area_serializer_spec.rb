require 'spec_helper'

describe AreaSerializer do
  let(:area) do
    {
      'area' => 'nl',
      'enabled' => { 'etmodel' => true, 'etengine' => true },
      'has_agriculture' => true,
      'co2_percentage_free' => 0.85
    }
  end

  let(:json) { described_class.new(area, detailed: detailed).as_json }

  context 'when detailed=true' do
    let(:detailed) { true }

    it 'includes the "area" attribute' do
      expect(json).to include('area' => 'nl')
    end

    it 'includes the "useable" attribute' do
      expect(json).to include('useable' => true)
    end

    it 'does not have the "enabled" attribute' do
      expect(json).not_to have_key('enabled')
    end

    it 'has the co2_percentage_free attribute' do
      expect(json).to include('co2_percentage_free' => 0.85)
    end

    it 'has the has_agriculture attribute' do
      expect(json).to include('has_agriculture' => true)
    end
  end

  context 'when detailed=true' do
    let(:detailed) { false }

    it 'includes the "area" attribute' do
      expect(json).to include('area' => 'nl')
    end

    it 'includes the "useable" attribute' do
      expect(json).to include('useable' => true)
    end

    it 'does not have the "enabled" attribute' do
      expect(json).not_to have_key('enabled')
    end

    it 'does not have the co2_percentage_free attribute' do
      expect(json).not_to include('co2_percentage_free' => 0.85)
    end

    it 'has the has_agriculture attribute' do
      expect(json).to include('has_agriculture' => true)
    end
  end
end
