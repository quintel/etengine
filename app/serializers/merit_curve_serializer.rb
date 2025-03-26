class MeritCurveSerializer
  # Dump the Merit::Curve instance into a MessagePack binary string.
  # We capture the values array, the intended length, and the default value.
  def self.dump(curve)
    data = {
      values: curve.to_a,
      length: curve.length,
      default: curve.instance_variable_get(:@default)
    }
    MessagePack.pack(data)
  end

  # Load the MessagePack binary string and instantiate a new Merit::Curve.
  def self.load(packed)
    data = MessagePack.unpack(packed, symbolize_keys: true)
    Merit::Curve.new(data[:values], data[:length], data[:default])
  end
end
