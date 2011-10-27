require 'spec_helper'

module Gql
  describe Goal do
    describe "#new" do
      it "should have a key" do
        g = Goal.new(:foo)
        g.key.should == :foo
      end
    end
  end
end