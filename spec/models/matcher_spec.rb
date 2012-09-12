require 'spec_helper'

describe "increase" do
  specify { -1.0.should_not increase}
  specify { 0.0.should_not increase}
  specify { 1.0.should increase}
  specify { nil.should_not increase}
end

describe "increase" do
  specify { -1.0.should decrease}
  specify { 0.0.should_not decrease}
  specify { 1.0.should_not decrease}
  specify { nil.should_not decrease}
end
