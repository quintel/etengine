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

describe "be_within" do
  specify { 0.0.should be_within(0.0, 0.0)}
  specify { 0.0.should be_within(0.0, 1.0)}

  specify { 100.0.should be_within(100.0, 0.0)}
  specify { -100.0.should be_within(-100.0, 0.0)}

  specify { 100.0.should be_within(100.0, 1.0)}

  specify {  99.0.should be_within(100.0, 1.0)}
  specify { 101.0.should be_within(100.0, 1.0)}
  
  specify {  98.9.should_not be_within(100.0, 1.0)}
  specify { 101.1.should_not be_within(100.0, 1.0)}

  specify { nil.should_not be_within(100.0, 2.0)}
  specify { (0.0/0.0).should_not be_within(100.0, 2.0)} # NaN
  specify { (1.0/0.0).should_not be_within(100.0, 2.0)} # Infinite

  specify { 101.1.should_not be_within(nil, 1.0)}
  specify { nil.should be_within(nil, 1.0)}

  specify { 0.0014.should be_within(0.001, 0.0)}
  specify { 0.0014.should be_within(0.001, 1.0)}

end

