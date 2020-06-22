require 'spec_helper'

module Qernel
  describe Node do
    skip do
      before do |example|
        # it_description = example.metadata[:description]
        context_description = example.metadata[:example_group][:description]
        @g = GraphParser.new(context_description).build
        @g.calculate
        @g.nodes.each do |node|
          instance_variable_set("@#{node.key}", node)
        end
      end

      context " # Simple graph
                electricity[1;0.8]: lft(80)  == s(1) ==> mid
                loss[1;0.2]:        loss(20) == s(1) ==> mid
                electricity[0.8]:   mid      == s(1) ==> rgt1
                bar[0.2]:           mid      == f(1) ==> rgt2" do

        before do
          allow(@rgt1).to receive(:primary_energy_demand?).and_return(true)
          allow(@rgt2).to receive(:primary_energy_demand?).and_return(true)
        end

        it "should calculate properly" do
          expect(@lft.demand).to eq(80.0)
          expect(@mid.demand).to eq(100.0)
          expect(@loss.demand).to eq(20.0)
          expect(@rgt1.demand).to eq(80.0)
          expect(@rgt2.demand).to eq(20.0)
        end

        it "if rgt1,rgt2 are primary" do
          expect(@lft.primary_demand).to eq(100.0)
          expect(@mid.primary_demand).to eq(100.0)
          expect(@rgt1.primary_demand).to eq(80.0)
          expect(@rgt2.primary_demand).to eq(20.0)
        end

        it "if rgt2 is not primary" do
          allow(@rgt2).to receive(:primary_energy_demand?).and_return(false)

          expect(@lft.primary_demand).to eq(80.0)
          expect(@rgt1.primary_demand).to eq(80.0)
          expect(@rgt2.primary_demand).to eq(0.0)
        end

        skip "should calculate primary_demand_of_electricity" do
          expect(@lft.query.primary_demand_of_electricity).to eq(80.0)
          expect(@mid.query.primary_demand_of_electricity).to eq(80.0)
          expect(@rgt1.query.primary_demand_of_electricity).to eq(80.0)
          expect(@rgt2.query.primary_demand_of_electricity).to eq(0.0)
        end
      end

      pending " # Graph with loop
                abc(80)  == s(1.0) ==> lft
                lft      == f(1.0) ==> mid
                lft      == c(200) ==> rgt(200)"

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

      context "# with loop
               #
               electricity: lft(90) == s(1) ==> mid
               electricity:                     mid == f(1.0) ==> loop
               electricity:                                       loop == i(nil) ==> mid
               electricity[1.0;0.4]:            mid == d(nil) ==> rgt
               loss[1.0;0.6]:               hlp(60) == f(1.0) ==> rgt" do

        before do
          allow(@rgt).to receive(:primary_energy_demand?).and_return(true)
        end


        specify { expect(@lft.demand).to eq(90.0) }
        specify { expect(@rgt.demand).to eq(100.0) }
        specify { expect(@mid.demand).to eq(90.0) }
        # d(nil) gets 30 demand
        # => f(1.0) gets 90 - 40 => 50
        specify { expect(@loop.demand).to eq(50.0) }
        #specify { @innerloop.demand.should == 100.0 }


        specify { expect(@lft.primary_demand).to eq(100.0) }
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
          allow(@rgt).to receive(:primary_energy_demand?).and_return(true)
        end

        specify { expect(@lft.demand).to eq(90.0) }
        specify { expect(@rgt.demand).to eq(100.0) }
        specify { expect(@mid.demand).to eq(90.0) }
        specify { expect(@loop.demand).to eq(50.0) }
        specify { expect(@innerloop.demand).to eq(100.0) }

        specify { expect(@lft.primary_demand).to eq(100.0) }
      end
    end
  end
end
