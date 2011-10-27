require 'spec_helper'

module Gql
  describe Goal do
    describe "#find" do
      it "creates a record if missing" do
        x = Goal.find(:foo)
        x.should be_kind_of(Goal)
      end
    end

    describe "#all" do
      before :each do
        Goal.clear
      end

      it "should be empty until a record is added" do
        Goal.all.should be_empty
      end

      it "should return new records" do
        foo = Goal.find(:foo)
        Goal.all.should include(foo)
      end
    end
  end
end