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