require 'spec_helper'

module Gql
  describe Goal do
    describe "#new" do
      it "should have a key" do
        g = Goal.new(:foo)
        g.key.should == :foo
      end
    end
    
    describe "#is_set?" do
      it "should return false if the user value is nil" do
        g = Goal.new(:foo)
        g.is_set?.should be_false
      end

      it "should return true if the user value is not nil" do
        g = Goal.new(:foo)
        g.user_value = 123
        g.is_set?.should be_true
      end
    end
  end
end