describe MeritCurveSerializer do
  let(:curve) { Merit::Curve.new([1.0, 2.0, 3.0], 5, 0.0) }

  it 'serializes and deserializes a Merit::Curve' do
    packed = described_class.dump(curve)
    unpacked = described_class.load(packed)

    expect(unpacked).to be_a(Merit::Curve)
    expect(unpacked.to_a).to eq([1.0, 2.0, 3.0, 0.0, 0.0])
  end
end
