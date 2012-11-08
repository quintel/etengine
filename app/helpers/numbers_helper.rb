module NumbersHelper
  def auto_number(value)
    return '-' if value.nil?
    return value unless value.is_a?(Numeric)
    return 'Infinity' if value.to_f.infinite?

    abs_value = value.abs
    if abs_value > 1_000_000_000
      _nwp(value.to_f / 1_000_000_000, 2) + " B"
    elsif abs_value > 10_000_000
      _nwp(value.to_f / 1_000_000, 2) + " M"
    elsif abs_value > 100_000
      _nwp(value.to_f / 1_000, 0) + " K"
    elsif abs_value > 100
      _nwp(value.to_f, 0)
    elsif abs_value >= 1 && value < 100
      _nwp(value, 2)
    elsif abs_value > 0 && value < 1
      _nwp(value, 3)
    elsif abs_value === 0
      0
    else
      value
    end
  end

  def _nwp(value, precision)
    number_with_precision value, :precision => precision,
                                 :separator => '.',    # decimal separator
                                 :delimiter => ','     # thousands separator
  end
end
