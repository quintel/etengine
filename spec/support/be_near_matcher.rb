RSpec::Matchers.define :be_within_a_percent do |expected|
  match do |actual|
    if actual.respond_to?(:finite?) && !actual.finite?
      expected.respond_to?(:finite?) && !expected.finite?
    elsif !actual.respond_to?(:to_f)
      actual == expected
    elsif actual.to_f == 0.0 && expected.to_f == 0.0
      true
    else
      ((1.0 - actual.to_f / expected) * 100.0).abs < 1.0
    end
  end

  failure_message_for_should do |actual|
    "got: #{actual}. But should be near #{expected}"
  end

  failure_message_for_should_not do |actual|
    "got: #{actual}. But should not to be near #{expected}"
  end

  description do
    "be near #{expected}"
  end
end

RSpec::Matchers.define :increase do
  match{ |actual| !actual.nil? && actual > 0.0 }

  failure_message_for_should do |actual|
    if actual == 0.0
      "expected an increase, but it decreased by: #{actual.inspect}"
    else
      "expected an increase, but decreased by #{actual.inspect}"
    end
  end
end

RSpec::Matchers.define :decrease do
  match { |actual| !actual.nil? && actual < 0.0 }

  failure_message_for_should do |actual|
    if actual == 0.0
      "expected a decrease, but it stayed the same: #{actual.inspect}"
    else
      "expected a decrease, but increase by #{actual.inspect}"
    end
  end
end

RSpec::Matchers.define :be_within do |expected, percent|
  match do |actual|
    if expected.nil? 
      actual.nil?
    else
      factor   = percent / 100.0

      if expected == 0.0 # allow for some rounding errors
        min_max = [-0.0001, 0.0001]
      else
        min_max = [
          expected * (1.0 - factor), 
          expected * (1.0 + factor)
        ].sort
      end
      
      range = Range.new *min_max
      range.include?(actual)
    end
  end

  failure_message_for_should do |actual|
    "Got: #{actual.andand.round(3).inspect}. But should be near #{expected}"
  end

  failure_message_for_should_not do |actual|
    "Got: #{actual.round(3)}. But should not to be near #{expected}"
  end

  description do
    "be near #{expected}"
  end
end