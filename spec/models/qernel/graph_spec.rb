require 'spec_helper'

module Qernel
  describe Graph, '#initialize' do
    it "should initialize without attributes" do
      @g = Qernel::Graph.new()
    end

    it "should initialize with converters []" do
      @g = Qernel::Graph.new([Qernel::Converter.new(id: 1, key: 'foo')])
    end
  end

  describe Graph, 'valid' do
    before { @g = Qernel::Graph.new() }
    subject { @g }

    its(:area) { should_not be_nil }

    describe "#converters=" do
      it "should #reset_memoized_methods when adding converters" do
        @g.should_receive(:reset_memoized_methods)
        @g.converters = []
      end

      it "should assign graph to converters" do
        converter = Qernel::Converter.new(id: 1, key: 'foo')
        @g.converters = [converter]
        converter.graph.should == @g
      end
    end
  end

  describe Graph do
    before do 
      @g = GraphParser.new(example.description).build
      @g.converters.each do |converter|
        instance_variable_set("@#{converter.key}", converter)
      end
    end
    
    context "Flex Max" do
      it "# Fill flex_max link upto max_demand
          mid(100) == f(1.0) ==> rgt1 
          mid      == f(1.0) ==> rgt2" do
        
        @rgt1.output_links.first.max_demand = 30.0
        @g.calculate
        
        @rgt1.demand.should ==  30.0 
        @rgt2.demand.should ==  70.0 
      end

      it "# flexible links have a default min_demand of 0.0
          mid(100) == c(120) ==> rgt1(nil)
          mid      == f(1.0) ==> rgt2(nil)" do
        @g.calculate

        @mid.demand.should ==  100.0
        @rgt1.demand.should == 120.0
        @rgt2.demand.should ==  0.0
      end

      it "# flexible with carrier electricity have no such min_demand of 0.0
          electricity: mid(100) == c(120) ==> rgt1(nil)
          electricity: mid      == f(1.0) ==> rgt2(nil)" do
        @g.calculate

        @mid.demand.should ==  100.0
        @rgt1.demand.should == 120.0
        @rgt2.demand.should == -20.0
      end

      # seb: skip implementatio of min_demand because it'll 
      #      complicate things quite a bit.
      #
      # it "# rgt1 min_demand: 30. Rgt1 should get all.
      #     mid(100) == f(1.0) ==> rgt1 
      #     mid      == f(1.0) ==> rgt2" do
      # 
      #   @rgt1.output_links.first.min_demand = 30.0
      #   @g.calculate
      #   
      #   @rgt1.demand.should == 100.0 
      #   @rgt2.demand.should ==   0.0 
      # end
    end

    context do
      
      before do
        @g.calculate
      end

      # ----- SYNTAX  ------------------------------------------------
    
      # defaults:
      # carrier: foo
      # conversion: 1.0
      # link_share: nil
      # demand: nil
      #
      # so:
      # "foo  == s ==> bar"
      # is equivalent to:
      # "foo[1.0;1.0]: foo(nil) == s(nil) ==> bar(nil)"


      # ----- Mutliple carriers ------------------------------------------------

      it "bar[0.5]: lft(100) == s(1.0) ==> rgt1 
          foo[0.5]: lft      == s(1.0) ==> rgt2" do

        @rgt1.demand.should == 50.0
        @rgt2.demand.should == 50.0
      end

      # ----- Share only ------------------------------------------------

      it "lft(100) == s(0.3) ==> rgt1(nil)
          lft      == s(0.7) ==> rgt2(nil)" do

        @rgt1.demand.should == 30.0
        @rgt2.demand.should == 70.0
      end

      # ----- Constant ------------------------------------------------

      it "mid(nil) == c(30) ==> rgt1 
          mid      == c(20) ==> rgt2" do

        @mid.demand.should ==  0.0 
        @rgt1.demand.should == 30.0 
        @rgt2.demand.should == 20.0 
      end

      it "mid(nil) == c(nil) ==> rgt1(80) 
          mid      == c(nil) ==> rgt2(20)" do

        @mid.demand.should == 100.0 
        @rgt1.demand.should == 80.0 
        @rgt2.demand.should == 20.0 
      end

      # ----- Flexible & Share  --------------------------------------

      it "mid(100) == s(0.8) ==> rgt1(nil) 
          mid      == f(1.0) ==> rgt2(nil)" do

        @rgt1.demand.should == 80.0
        @rgt2.demand.should == 20.0 
      end

      # ----- Flexible & Constant  --------------------------------------

      it "# If mid has no output link, it becomes 0.0
          mid(nil) == c(80)  ==> rgt1(nil) 
          mid      == f(1.0) ==> rgt2(nil)" do

        @mid.demand.should == 0.0
        @rgt1.demand.should == 80.0
        @rgt2.demand.should == 0.0
      end

      it "# This works, because mid gets demand from lft
          lft(100) == s(1)  ==> mid(nil)
          mid(nil) == c(80) ==> rgt1(nil) 
          mid      == f(1)  ==> rgt2(nil)" do

        @lft.demand.should ==  100.0

        @mid.demand.should ==  100.0
        @rgt1.demand.should == 80.0
        @rgt2.demand.should == 20.0
      end

      it "# if constant share is nil, assign right demand to the mid
          mid(nil) == c(nil) ==> rgt1(80)
          mid      == f(1.0) ==> rgt2(nil)" do

        @rgt1.demand.should == 80.0

        @mid.demand.should ==  80.0
        @rgt2.demand.should ==  0.0
      end


      # ----- Inversed Flexible  --------------------------------------

      it "# if outputs are higher then inputs fill up inversed_flexible
          # with the remainder.
          bar:   loss(nil) == i(nil)   ==> mid(nil)
          foo:   lft1(50)  == s(1)   ==> mid
          foo:   mid       == c(nil) ==> rgt1(70)" do
      
        @rgt1.demand.should == 70.0
        @lft1.demand.should == 50.0

        @mid.demand.should ==  70.0
        @loss.demand.should == 20.0
      end

      it "# we don't want inversed_flexible to become negative
          # if outputs are higher then inputs set inversed_flexible to 0.0
          bar:   loss(nil) == i(nil)   ==> mid(nil)
          foo:   lft1(100) == s(1)   ==> mid
          foo:   mid       == c(nil) ==> rgt1(40) 
          foo:   mid       == f(nil) ==> rgt2(30)" do
      
        @lft1.demand.should == 100.0
        @mid.demand.should ==  100.0
        @rgt1.demand.should == 40.0
        @rgt2.demand.should == 30.0
        @loss.demand.should ==  0.0
      end

      it "# dependent consumes everything
          loss:      loss(nil)      == i(nil) ==> mid(nil)
          foo[1;0.5]: el_output(nil) == d(nil) ==> mid
          bar[1;0.5]: hw_demand(60)  == s(1.0) ==> mid
          foo:        mid            == c(nil) ==> rgt1(120)" do
      
        @rgt1.demand.should == 120.0
        @hw_demand.demand.should == 60.0

        @mid.demand.should == 120.0
        @el_output.demand.should == 60.0
        @loss.demand.should == 0.0
      end

      it "# dependent takes it's cut from the total demand (120)
          # is not depending on the other output-links
          loss:      loss(nil)      == i(nil) ==> mid(nil)
          foo[1;0.5]: el_output(nil) == d(nil) ==> mid
          bar[1;0.5]: hw_demand(50)  == s(1.0) ==> mid
          foo:        mid            == c(nil) ==> rgt1(120)" do
      
        @rgt1.demand.should == 120.0
        @hw_demand.demand.should == 50.0

        @mid.demand.should == 120.0
        @el_output.demand.should == 60.0
        @loss.demand.should == 10.0
      end

      # ----- Loops  --------------------------------------

      it "# If right side is lower, fill up flexible link
          loss(nil) == i(nil) ==> mid(nil)
          lft1(100) == s(1)   ==> mid 
                                  mid == f(nil) ==> loss
                                  mid == c(nil) ==> rgt1(40)" do
        @lft1.demand.should == 100.0
        @mid.demand.should ==  100.0
        @rgt1.demand.should == 40.0
        @loss.demand.should == 60.0
      end

      it "# If right side is higher, fill up inversed_flexible link
          # sb: HELP: but loss demand stays 0.0???
          loss(nil) == i(nil) ==> mid(nil)
          lft1(100) == s(1)   ==> mid 
                                  mid == f(nil) ==> loss
                                  mid == c(nil) ==> rgt1(140)" do
        @lft1.demand.should == 100.0
        @mid.demand.should ==  140.0
        @rgt1.demand.should == 140.0
        @loss.demand.should ==  40.0
      end

      # ----- Dependent  --------------------------------------

      it "bar[1.0;0.7]: hw_demand(70) == s(1) ==> chp(nil)
          foo[1.0;0.3]: el_output(nil) == d()  ==> chp(nil)
          foo:          chp(nil)       == s(1) ==> rgt(nil) " do
      
        @hw_demand.demand.should == 70.0
        @el_output.demand.should == 30.0
        @chp.demand.should == 100.0
        @rgt.demand.should == 100.0
      end

      it "bar[1.0;0.7]: hw_demand(70)  == s(1.0) ==> chp
          foo[1.0;0.3]: el_output(40)  == d      ==> chp
          foo:          el_output      == f(nil) ==> rgt1
          #foo:          el_output      == s(0.6) ==> rgt2" do
      
        @hw_demand.demand.should == 70.0
        @chp.demand.should == 100.0
        @el_output.demand.should == 40.0

        @rgt1.demand.should == 10.0
      end

      it "# BUG/INCONSISTENCY
          # Dependent together with shares do not work correctly!!
          # Share seems to be calculated first or doesn't take into account
          # dependent value
          bar[1.0;0.7]: hw_demand(70)  == s(1.0) ==> chp
          foo[1.0;0.3]: el_output(40)  == d      ==> chp
          foo:          el_output      == f(nil) ==> rgt1
          foo:          el_output      == s(0.6) ==> rgt2" do
      
        @hw_demand.demand.should == 70.0
        @chp.demand.should == 100.0
        @el_output.demand.should == 40.0

        @rgt2.demand.should == 24.0
        @rgt1.demand.should == 0.0
      end


      # it "# with same converter does not work
      #     foo[1.0]:     hw_demand(70)  == s(1) ==> chp(nil)
      #     foo[1.0]:     el_output(nil) == d()  ==> chp(nil)
      #     foo:          chp(nil)       == s(1) ==> rgt(nil) " do
      #   
      #   @hw_demand.demand.should == 70.0
      #   @el_output.demand.should == 30.0
      #   @chp.demand.should == 100.0
      #   @rgt.demand.should == 100.0
      # end

      # ----- Reversed  --------------------------------------

      it "lft == s(1.0) ==< rgt(100)" do
        @lft.demand.should == 100.0
        @rgt.demand.should == 100.0
      end

      it "lft == s(1.0) ==< rgt(100)
          lft == s(1.0) ==< rgt2(100)" do

        @lft.demand.should == 200.0
      end

      it "lft == s(1.0) ==< rgt(100)
          lft == f(nil) ==< rgt2(100)" do

        @lft.demand.should == 200.0
      end

      it "lft      == s(1.0) ==< rgt1(100)
          lft      == f(nil) ==< rgt2(100)
          lft2(50) == s(1.0) ==> rgt2" do

        @lft.demand.should == 150.0
        @rgt2.demand.should == 100.0
      end

      # ----- Reversed Dependent functionality  ------------------

      describe "Reversed Dependent functionality" do
      
        it "# dependent as reversed share(1)
            bar[1.0;0.7]: hw_demand(70)  == s(1) ==> chp(nil)
            foo[1.0;0.3]: el_output(nil) == s(1) ==< chp(nil)
            foo:          chp(nil)       == s(1) ==> rgt(nil) " do
      
          @hw_demand.demand.should == 70.0
          @el_output.demand.should == 30.0
          @chp.demand.should == 100.0
          @rgt.demand.should == 100.0
        end

        it "# dependent as reversed flexible
            bar[1.0;0.7]: hw_demand(70)  == s(1) ==> chp(nil)
            foo[1.0;0.3]: el_output(nil) == f(nil) ==< chp(nil)
            foo:          chp(nil)       == s(1) ==> rgt(nil) " do
      
          @hw_demand.demand.should == 70.0
          @el_output.demand.should == 30.0
          @chp.demand.should == 100.0
          @rgt.demand.should == 100.0
        end

        it "bar[1.0;0.7]: hw_demand(70)  == s(1.0) ==> chp
            foo[1.0;0.3]: el_output(40)  == s(1.0) ==< chp
            foo:          el_output      == f(nil) ==> rgt1" do
      
          @hw_demand.demand.should == 70.0
          @chp.demand.should == 100.0
          @el_output.demand.should == 40.0

          @rgt1.demand.should == 10.0
        end

        it "# BUG/INCONSISTENCY
            # Dependent together with shares do not work correctly!!
            # Share seems to be calculated first or doesn't take into account
            # dependent value
            bar[1.0;0.7]: hw_demand(70)  == s(1.0) ==> chp
            foo[1.0;0.3]: el_output(40)  == s(1.0) ==< chp
            foo:          el_output      == f(nil) ==> rgt1
            foo:          el_output      == s(0.6) ==> rgt2" do
      
          @hw_demand.demand.should == 70.0
          @chp.demand.should == 100.0
          @el_output.demand.should == 40.0

          @rgt2.demand.should == 24.0
          @rgt1.demand.should == 0.0
        end

      end

      # ----- Reversed & Inversed Flexible functionality  -----------------------

      # not working
      #
      # it "# if outputs are higher then inputs fill up inversed_flexible
      #     # with the remainder.
      #     loss:  loss(nil) == f(nil) ==< mid(nil)
      #     foo:   lft1(50)  == s(1)   ==> mid
      #     foo:   mid       == c(nil) ==> rgt1(70)" do
      #   
      #   @rgt1.demand.should == 70.0
      #   @lft1.demand.should == 50.0
      # 
      #   @mid.demand.should ==  70.0
      #   @loss.demand.should == 20.0
      # end
    end
  end

  describe "reversed" do
    before do
      @g = Qernel::GraphParser.create("lft == s(1.0) ==< rgt(100)")
      @rgt = @g.converter(:rgt)
      @lft = @g.converter(:lft)
      @l = @g.links.first
    end

    it "should have reversed link" do
      @l.reversed.should be_true
      @l.calculated_by_right?.should be_true
      @l.send(:input).should == @g.converter(:rgt).slots.first
      @l.send(:input).expected_external_value.should == 100.0
      @l.send(:input_external_demand).should == 100.0
    end

    it "ready" do
      @lft.input(:foo).passive_links.length.should == 1
      @rgt.output(:foo).passive_links.length.should == 0
    end

    it "should calculate link" do
      @l.send(:calculate_share).should == 100.0
      @l.send(:calculate).should == 100.0
      @l.value.should == 100.0
    end

    it "should calculate rgt slot" do
      @rgt.output(:foo).calculate
      @l.value.should == 100.0
    end

    it "lft slot not ready, rgt slot ready" do
      @rgt.output(:foo).ready?.should be_true
      @lft.input(:foo).ready?.should be_false
    end

    it "should calculate link" do
      @l.calculate.should == 100.0
    end

    context "calculated" do
      before do 
        @g.calculate
      end

      # specify { @l.value.should == 100.0 }
    end
  end
  
  describe "Policy Goals" do
    before do
      @graph = Graph.new
    end
    
    describe "#goals" do
      it "should have no goals on initialize" do
        @graph.goals.should be_empty
      end

      it "should return all goals" do
        goal = Goal.new(:foo)
        @graph.goals << goal
        @graph.goals.should include(goal)
      end
    end

    describe "#goal" do
      it "should get a goal by key" do
        goal = Goal.new(:foo)
        @graph.goals << goal
        @graph.goal(:foo).should == goal
      end

      it "should return nil if a goal is missing" do
        @graph.goal(:bar).should be_nil
      end
    end
    
    describe "#find_or_create_goal" do
      it "should create a goal object as needed" do
        @graph.goals.should be_empty
        @graph.find_or_create_goal(:foobar).should be_kind_of(Goal)
        @graph.goals.size.should == 1
      end
    end
    
    # Check query_interface_spec.rb to see how we update goals through GQL
  end
  

end

