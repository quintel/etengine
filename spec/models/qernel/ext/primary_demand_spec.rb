require 'spec_helper'

module Qernel
  describe Converter do
    pending do 
      before do 
        # it_description = example.metadata[:description]
        context_description = example.metadata[:example_group][:description]
        @g = GraphParser.new(context_description).build
        @g.calculate
        @g.converters.each do |converter|
          instance_variable_set("@#{converter.key}", converter)
        end
      end

      context " # Simple graph
                electricity[1;0.8]: lft(80)  == s(1) ==> mid
                loss[1;0.2]:        loss(20) == s(1) ==> mid
                electricity[0.8]:   mid      == s(1) ==> rgt1
                bar[0.2]:           mid      == f(1) ==> rgt2" do

        before do
          @rgt1.stub!(:primary_energy_demand?).and_return(true)
          @rgt2.stub!(:primary_energy_demand?).and_return(true)
        end

        it "should calculate properly" do
          @lft.demand.should ==  80.0
          @mid.demand.should ==  100.0
          @loss.demand.should == 20.0
          @rgt1.demand.should == 80.0
          @rgt2.demand.should == 20.0
        end

        it "if rgt1,rgt2 are primary" do
          @lft.primary_demand.should == 100.0
          @mid.primary_demand.should == 100.0
          @rgt1.primary_demand.should == 80.0
          @rgt2.primary_demand.should == 20.0
        end

        it "if rgt2 is not primary" do
          @rgt2.stub!(:primary_energy_demand?).and_return(false)

          @lft.primary_demand.should == 80.0
          @rgt1.primary_demand.should == 80.0
          @rgt2.primary_demand.should == 0.0
        end

        pending "should calculate primary_demand_of_electricity" do
          @lft.query.primary_demand_of_electricity.should == 80.0
          @mid.query.primary_demand_of_electricity.should == 80.0
          @rgt1.query.primary_demand_of_electricity.should == 80.0
          @rgt2.query.primary_demand_of_electricity.should == 0.0
        end
      end

      pending " # Graph with loop
                abc(80)  == s(1.0) ==> lft
                lft      == f(1.0) ==> mid
                lft      == c(200) ==> rgt(200)" do

        before do
          @rgt.stub!(:primary_energy_demand?).and_return(true)
        end

        
        specify { @lft.demand.should == 200.0 }
        specify { @mid.demand.should == 120.0 }
        specify { @rgt.demand.should == 200.0 }
        

        it "if rgt,rgt2 are primary" do
          @lft.primary_demand.should == 200.0
          @mid.primary_demand.should == 200.0
          @rgt.primary_demand.should == 80.0
        end
      end

      context "# with loop
               # 
               electricity: lft(90) == s(1) ==> mid
               electricity:                     mid == f(1.0) ==> loop
               electricity:                                       loop == i(nil) ==> mid
               electricity[1.0;0.4]:            mid == d(nil) ==> rgt
               loss[1.0;0.6]:               hlp(60) == f(1.0) ==> rgt" do
        
        before do
          @rgt.stub!(:primary_energy_demand?).and_return(true)
        end

        
        specify { @lft.demand.should ==  90.0 }
        specify { @rgt.demand.should == 100.0 }
        specify { @mid.demand.should ==  90.0 }
        # d(nil) gets 30 demand
        # => f(1.0) gets 90 - 40 => 50
        specify { @loop.demand.should == 50.0 }
        #specify { @innerloop.demand.should == 100.0 }
        

        specify { @lft.primary_demand.should == 100.0 }
      end

      context "# with inner loop
               # 
               electricity: lft(90) == s(1) ==> mid
               electricity:                     mid == f(1.0) ==> loop
               electricity:                                       loop == i(nil) ==> mid
               electricity[1.0;0.4]:            mid == d(nil) ==> rgt
               loss[1.0;0.6]:               hlp(60) == f(1.0) ==> rgt
               electricity[1.0;0.4]:                              loop == d(nil) ==> innerloop
               electricity[1.0;0.6]:                    outer_loop(60) == s(1.0) ==> innerloop
               " do
        
        before do
          @rgt.stub!(:primary_energy_demand?).and_return(true)
        end

        specify { @lft.demand.should ==  90.0 }
        specify { @rgt.demand.should == 100.0 }
        specify { @mid.demand.should ==  90.0 }
        specify { @loop.demand.should == 50.0 }
        specify { @innerloop.demand.should == 100.0 }
        
        specify { @lft.primary_demand.should == 100.0 }
      end
    end
  end
end
