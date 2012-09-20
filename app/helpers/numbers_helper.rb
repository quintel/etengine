module NumbersHelper
  def auto_number(value)
    return '-' if value.nil?
    return value unless value.is_a?(Numeric)
    return 'Infinity' if value.to_f.infinite?

    abs_value = value.abs
    if abs_value > 1_000_000_000
      number_with_precision(value.to_f / 10**9, :precision => 2, :separator => ',', :delimiter => ".") + " B"
    elsif abs_value > 10_000_000
      number_with_precision(value.to_f / 10**6, :precision => 2, :separator => ',', :delimiter => ".") + " M"
    elsif abs_value > 100_000
      number_with_precision(value.to_f / 10**3, :precision => 0, :separator => ',', :delimiter => ".") + " K"
    elsif abs_value > 100
      number_with_precision(value.to_f, :precision => 0, :separator => ',', :delimiter => ".")
    elsif abs_value >= 1 && value < 100
      number_with_precision value, :precision => 2, :separator => ',', :delimiter => "."
    elsif abs_value > 0 && value < 1
      number_with_precision value, :precision => 3, :separator => ',', :delimiter => "."
    elsif abs_value === 0
      0
    else
      value
    end
  end

  # Formats number nicely, ignoring the unit and without transformations
  def nice_number(x)
    return 0 if x === 0
    abs_value = x.abs
    precision = if abs_value >= 1000
      0
    else
      2
    end

    x = number_with_precision x, :precision => precision
    number_with_delimiter(x, :delimiter => ".", :separator => ',')
  end
end
