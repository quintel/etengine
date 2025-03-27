class MeritCurveSerializer
  # Dump the Merit::Curve instance into a MessagePack binary string.
  def self.dump(curve)
    MessagePack.pack(curve.to_a)
  end

  # Load the MessagePack binary string and instantiate a new Merit::Curve.
  def self.load(packed)
    Merit::Curve.new(MessagePack.unpack(packed))
  end
end
