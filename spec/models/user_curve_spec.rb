# frozen_string_literal: true

require 'spec_helper'

describe UserCurve do
  let(:scenario) { create(:scenario) }
  let(:curve_data) { [0.0, 1.0, 2.0, 3.0] }

  it 'serializes and deserializes to a Merit::Curve' do
    curve = Merit::Curve.new(curve_data, 8760, 0.0)
    user_curve = UserCurve.create!(scenario:, key: 'some_curve', curve:)

    user_curve.reload
    expect(user_curve.curve).to be_a(Merit::Curve)
    expect(user_curve.curve.to_a).to eq(curve_data + [0.0] * (8760 - 4))
  end

  it 'validates uniqueness of key per scenario' do
    UserCurve.create!(scenario:, key: 'some_curve', curve: Merit::Curve.new)
    duplicate = UserCurve.new(scenario:, key: 'some_curve', curve: Merit::Curve.new)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:key]).to include('has already been taken')
  end
end
