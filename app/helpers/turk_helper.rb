module TurkHelper
  def turk_it(key, result)
    present = result.first.last
    future = result.last.last
    if present.is_a?(Numeric) && future.is_a?(Numeric)
       <<-STR
it "checks #{key}" do
  @present.#{key}.should be_within(TOLERANCE).of(#{present.round(3)})
  @future.#{key}.should be_within(TOLERANCE).of(#{future.round(3)})
end
      STR
    end
  end
end
