require 'spec_helper'

module Gql

describe Gql do

  describe "UPDATE" do
    before do
      @graph = Qernel::GraphParser.new("lft(100) == s(1.0) ==> rgt(120)").build
      Current.instance.stub_chain(:gql, :calculated?).and_return(true)
      @q = QueryInterface.new(@graph)
    end

    it "should query" do
      @q.query("V(lft; demand)").should == 100.0
      @q.query("V(rgt; demand)").should == 120.0
    end

    it "should UPDATE" do
      @q.query("UPDATE(V(lft), demand, 130)")
      @q.query("V(lft; demand)").should == 130.0
    end

    it "should UPDATE multiple" do
      @q.query("UPDATE(V(lft, rgt), demand, 130)")
      @q.query("V(lft; demand)").should == 130.0
      @q.query("V(rgt; demand)").should == 130.0
    end

    it "should UPDATE referencing an attribute from UPDATE_OBJECT()" do
      @q.query("UPDATE(V(lft), demand, PRODUCT(V(UPDATE_OBJECT();demand),3))")
      @q.query("V(lft; demand)").should == 300.0
    end

    it "should UPDATE mulitple referencing an attribute from UPDATE_OBJECT()" do
      @q.query("UPDATE(V(lft, rgt), demand, PRODUCT(V(UPDATE_OBJECT();demand),3))")
      @q.query("V(lft; demand)").should == 300.0
      @q.query("V(rgt; demand)").should == 360.0
    end

    it "should UPDATE mulitple referencing an attribute from UPDATE_COLLECTION()" do
      # updates the demand with how many objects there are to be update
      @q.query("UPDATE(V(lft, rgt), demand, COUNT(UPDATE_COLLECTION()))")
      @q.query("V(lft; demand)").should == 2
      @q.query("V(rgt; demand)").should == 2
    end

    it "should UPDATE mulitple using EACH" do
      @q.query("EACH( UPDATE(V(lft),demand,1), UPDATE(V(rgt),demand,2) )")
      @q.query("V(lft; demand)").should == 1.0
      @q.query("V(rgt; demand)").should == 2.0
    end


    it "should UPDATE using USER_INPUT()" do
      @q.query("UPDATE(V(lft),demand,USER_INPUT())", 300)
      @q.query("V(lft; demand)").should == 300.0
    end


  end
end

end
