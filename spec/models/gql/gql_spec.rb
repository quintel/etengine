require 'spec_helper'

module Gql

describe Gql do

  describe "Integration Testing" do
    before do
      @gql = Current.gql = Gql.new(nil)
      p = Qernel::GraphParser.new("lft(100) == s(1.0) ==> rgt()").build
      f = Qernel::GraphParser.new("lft(100) == s(1.0) ==> rgt()").build
      p.stub!(:dataset).and_return(Dataset.new)
      f.stub!(:dataset).and_return(Dataset.new)

      @gql.stub!(:present_graph).and_return( p )
      @gql.stub!(:future_graph ).and_return( f )
    end
    
    it "should properly calculate" do
      @gql.query("present:V(lft; demand)").should == 100.0
      @gql.query("present:V(rgt; demand)").should == 100.0
      @gql.query("future:V(lft; demand)").should == 100.0
      @gql.query("future:V(rgt; demand)").should == 100.0
    end

    it "should properly calculate when running manually" do
      @input = Input.new(:query => "UPDATE(V(lft),demand,USER_INPUT())")
      Current.gql.future.query(@input, 300)

      @gql.query("future:V(lft; demand)").should  == 300.0
      @gql.query("present:V(lft; demand)").should == 100.0
    end

    it "should properly calculate when defined in user_values" do
      @input = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())")
      @gql.scenario.user_values = {@input.id => 300}

      @gql.query("present:V(lft; demand)").should == 100.0
      @gql.query("future:V(lft; demand)").should  == 300.0
    end

    it "should update only present with updateable_period = 'present'" do
      @input = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())", :updateable_period => 'present')
      @gql.scenario.user_values = {@input.id => 300}

      @gql.query("present:V(lft; demand)").should == 300.0
      @gql.query("future:V(lft; demand)").should  == 100.0
    end

    it "should update both with updateable_period = 'both'" do
      @input = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())", :updateable_period => 'both')
      @gql.scenario.user_values = {@input.id => 300}

      @gql.query("present:V(lft; demand)").should == 300.0
      @gql.query("future:V(lft; demand)").should  == 300.0
    end

    it "should work with mutliple updates" do
      @input1 = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())", :updateable_period => 'future' )
      @input2 = Input.create!(:query => "UPDATE(V(lft),demand,USER_INPUT())", :updateable_period => 'present')
      @input3 = Input.create!(:query => "UPDATE(V(rgt),demand,USER_INPUT())", :updateable_period => 'future')

      @gql.scenario.user_values = {@input1.id => 300, @input2.id => 200, @input3.id => 250}

      @gql.query("future:V(lft; demand)").should == 300.0
      @gql.query("future:V(rgt; demand)").should  == 250.0
      @gql.query("present:V(lft; demand)").should  == 200.0
    end
  end

  context "basic graph" do
    before do
      @graph = Qernel::GraphParser.new("lft(100) == s(1.0) ==> rgt(120)").build
      Current.instance.stub_chain(:gql, :calculated?).and_return(true)
      @q = QueryInterface.new(@graph)
    end

    describe "USER_INPUT() values" do
      pending "should update 5 as absolute value" do
        @q.query("UPDATE(V(lft),demand,USER_INPUT())", "5")
        @q.query("V(lft; demand)").should == 5.0
      end

      pending "should update 5% as total relative value" do
        @q.query("UPDATE(V(lft),demand,USER_INPUT())", "5%")
        @q.query("V(lft; demand)").should == 105.0
      end
    end

    describe "UPDATE" do
      it "should query" do
        @q.query("V(lft; demand)").should == 100.0
        @q.query("V(rgt; demand)").should == 120.0
      end

      describe "UPDATE with static values" do
        it "should UPDATE" do
          @q.query("UPDATE(V(lft), demand, 130)")
          @q.query("V(lft; demand)").should == 130.0
        end

        it "should UPDATE multiple" do
          @q.query("UPDATE(V(lft, rgt), demand, 130)")
          @q.query("V(lft; demand)").should == 130.0
          @q.query("V(rgt; demand)").should == 130.0
        end
      end

      describe "UPDATE with dynamic USER_INPUT()" do
        it "should UPDATE using USER_INPUT()" do
          @q.query("UPDATE(V(lft),demand,USER_INPUT())", 300)
          @q.query("V(lft; demand)").should == 300.0
        end
      end


      describe "UPDATE_OBJECT" do
        it "should UPDATE referencing an attribute from UPDATE_OBJECT()" do
          @q.query("UPDATE(V(lft), demand, PRODUCT(V(UPDATE_OBJECT();demand),3))")
          @q.query("V(lft; demand)").should == 300.0
        end

        it "should UPDATE mulitple referencing an attribute from UPDATE_OBJECT()" do
          @q.query("UPDATE(V(lft, rgt), demand, PRODUCT(V(UPDATE_OBJECT();demand),3))")
          @q.query("V(lft; demand)").should == 300.0
          @q.query("V(rgt; demand)").should == 360.0
        end
      end

      describe "UPDATE_COLLECTION" do
        it "should UPDATE mulitple referencing an attribute from UPDATE_COLLECTION()" do
          # updates the demand with how many objects there are to be update
          @q.query("UPDATE(V(lft, rgt), demand, COUNT(UPDATE_COLLECTION()))")
          @q.query("V(lft; demand)").should == 2
          @q.query("V(rgt; demand)").should == 2
        end
      end

      describe "EACH" do
        it "should UPDATE mulitple commands defined in EACH" do
          @q.query("EACH( UPDATE(V(lft),demand,1), UPDATE(V(rgt),demand,2) )")
          @q.query("V(lft; demand)").should == 1.0
          @q.query("V(rgt; demand)").should == 2.0
        end
      end
    end
  end
end

end
