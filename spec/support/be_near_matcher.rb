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

RSpec::Matchers.define :be_near do |expected|
  match do |actual|
    (actual - expected).abs < 0.01
  end

  failure_message_for_should do |actual|
    "expected #{actual} to be near #{expected}"
  end

  failure_message_for_should_not do |actual|
    "expected #{actual} not to be near #{expected}"
  end

  description do
    "be near #{expected}"
  end
end