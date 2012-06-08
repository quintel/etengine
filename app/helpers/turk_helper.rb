module TurkHelper
  def turk_it(key, result) 
    present = result.first.last
    future = result.last.last
    if present.is_a?(Numeric) && future.is_a?(Numeric)
       <<-STR
it "checks #{key}" do
  @present.#{key}.should be_within(#{present.round(3)}, TOLERANCE)
  @future.#{key}.should be_within(#{future.round(3)}, TOLERANCE)
end
      STR
    end
  end
end