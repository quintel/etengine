require 'spec_helper'

module Qernel
  describe Converter do
    before do 
      # it_description = example.metadata[:description]
      context_description = example.metadata[:example_group][:description]
      @g = GraphParser.new(context_description).build
      @g.calculate
      @g.converters.each do |converter|
        instance_variable_set("@#{converter.key}", converter)
      end
    end

    context " electricity[1;0.8]: lft(80)  == s(1)  ==> mid
              loss[1;0.2]:        loss(20) == s(1)  ==> mid
              electricity[0.8]:   mid      == s(1)  ==> rgt1
              bar[0.2]:           mid      == f(1)  ==> rgt2" do

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

      it "if rgt2 is environment?" do
        @rgt2.stub!(:environment?).and_return(true)

        @lft.primary_demand.should == 80.0
        @rgt1.primary_demand.should == 80.0

        # incorrect behaviour tested separately
        # @rgt2.primary_demand.should == 0.0
      end

      it "if rgt2 is environment? rgt2.primary_demand calculates wrongly" do
        @rgt2.stub!(:environment?).and_return(true)
        @rgt2.primary_demand.should == 20.0
      end

      it "should calculate primary_demand_of_electricity" do
        @lft.query.primary_demand_of_electricity.should == 80.0
        @mid.query.primary_demand_of_electricity.should == 80.0
        @rgt1.query.primary_demand_of_electricity.should == 80.0
        @rgt2.query.primary_demand_of_electricity.should == 0.0
      end
    end
  end

end
