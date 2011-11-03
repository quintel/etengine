module NumbersHelper
  # TODO refactor (seb 2010-10-11)
  def auto_number(value)
    return '-' if value.nil?
    return value unless value.is_a?(Numeric)
    return 'Infinity' if value.to_f.infinite?

    if value > 10**8
      number_with_precision(value.to_f / 10**9, :precision => 2, :delimiter => ",") + " B"
    elsif value > 10**5
      number_with_precision(value.to_f / 10**6, :precision => 2, :delimiter => ",") + " M"
    elsif value > 10**2
      number_with_precision(value.to_f / 10**3, :precision => 2, :delimiter => ",") + " K"
    elsif value >= 1 && value < 100
      number_with_precision value, :precision => 2
    elsif value > 0 && value < 1
      number_with_precision value, :precision => 3
    elsif value === 0
      0
    else
      value
    end
  end
end
