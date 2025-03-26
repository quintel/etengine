# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gql::CustomCurveCollection do
  let(:collection) { described_class.from_scenario(scenario) }
  let(:scenario) { FactoryBot.create(:scenario) }

  context 'with a scenario containing two valid user curves' do
    let(:curve_1_values) { File.read('spec/fixtures/files/price_curve.csv').lines.map(&:to_f) }
    let(:curve_2_values) { File.read('spec/fixtures/files/random_curve.csv').lines.map(&:to_f) }

    before do
      keys = Etsource::Config.user_curves.keys

      create(:user_curve, scenario:, key: "#{keys[0]}_curve", curve: Merit::Curve.new(curve_1_values))
      create(:user_curve, scenario:, key: "#{keys[1]}_curve", curve: Merit::Curve.new(curve_2_values))
    end

    it 'has two curves' do
      expect(collection.length).to eq(2)
    end

    it 'contains both curves' do
      expect(collection.keys).to match_array([
        Etsource::Config.user_curves.keys[0],
        Etsource::Config.user_curves.keys[1]
      ])
    end

    it 'has the first user curve values' do
      expect(collection.fetch(Etsource::Config.user_curves.keys[0])).to eq(curve_1_values)
    end

    it 'has the second user curve values' do
      expect(collection.fetch(Etsource::Config.user_curves.keys[1])).to eq(curve_2_values)
    end
  end

  context 'with a scenario containing an invalid user curve key' do
    before do
      create(:user_curve, scenario:, key: 'invalid_curve', curve: Merit::Curve.new([1.0] * 8760))
    end

    it 'does not contain the invalid curve' do
      expect(collection.length).to eq(0)
    end
  end
end
