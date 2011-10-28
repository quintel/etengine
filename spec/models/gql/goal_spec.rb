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
    
    describe "#[]=" do
      it "should assign an attribute using the [key]= value syntax" do
        g = Goal.new(:foo)
        g[:user_value] = 123
        g.user_value.should == 123
      end
      
      it "should not assign invalid attributes" do
        g = Goal.new(:foo)
        lambda { g[:bar] = 123 }.should_not raise_error
        lambda { g.bar }.should raise_error
      end
    end
  end
end