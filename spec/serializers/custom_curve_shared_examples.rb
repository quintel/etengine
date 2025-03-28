# frozen_string_literal: true

RSpec.shared_examples_for 'a custom curve Serializer' do
  let(:json) { described_class.new(curve).as_json }

  context 'with a stored curve' do
    let(:curve_data) { Array.new(8760) { rand(10.0..100.0) } }

    let(:curve) do
      FactoryBot.create(:user_curve).tap do |uc|
        uc.curve = Merit::Curve.new(curve_data)
        uc.save!
      end
    end

    it 'includes the curve name' do
      expect(json).to include(name: curve.key)
    end

    it 'includes the serialized size' do
      expect(json).to include(size: curve[:curve].bytesize)
    end

    it 'includes the creation date' do
      expect(json).to include(date: curve.created_at.utc)
    end

    it 'includes curve stats' do
      expect(json[:stats][:length]).to eq(8760)
      expect(json[:stats][:min_at]).to be_a(Integer)
      expect(json[:stats][:max_at]).to be_a(Integer)
    end
  end

  context 'with no stored curve' do
    let(:curve) do
      FactoryBot.create(:user_curve, key: 'invalid_key')
    end

    it { expect(json).to eq({}) }
  end
end
