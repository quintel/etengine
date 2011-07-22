require 'spec_helper'

module Qernel

  describe Graph, '#initialize' do
    it "should initialize without attributes" do
      @g = Qernel::Graph.new()
    end

    it "should initialize with converters []" do
      @g = Qernel::Graph.new([Qernel::Converter.new(1, 'foo')])
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
        converter = Qernel::Converter.new(1, 'foo')
        @g.converters = [converter]
        converter.graph.should == @g
      end
    end
  end

  describe Graph, "Sample graphs" do
    before do
      @crr_el  = Carrier.new(2, 'el', '', 1.0)
      @crr_hw  = Carrier.new(3, 'hw', '', 1.0)
      @g = Graph.new.with({})
    end

    describe "graph lft => rgt" do
      before do 
        @lft, @rgt = @g.with_converters(
          :lft => {:demand => 100.0},
          :rgt => {:demand => nil}
        )
        @link = @g.connect(:lft, :rgt, @crr_el).with(:share => 1.0)
      end

      it "should make converters accessible" do
        @g.converter(:lft).should == @lft
        @g.converter(:rgt).should == @rgt
      end

      it "should connect properly" do
        @link.parent.should == @lft
        @link.child.should == @rgt
        @link.carrier.should == @crr_el
        @lft.demand.should == 100.0
        @rgt.demand.should == nil
        @lft.input(:el).conversion == 1.0
        @rgt.output(:el).conversion == 1.0
      end

      it "should calculate" do
        @g.calculate
        @rgt.demand.should == 100.0
      end
    end
  end


  describe Graph do
    before do 
      @g = GraphParser.new(example.description).build
      @g.calculate
      @g.converters.each do |converter|
        instance_variable_set("@#{converter.key}", converter)
      end
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

    it "# flexible normally should not become negative
        mid(100) == c(120) ==> rgt1(nil)
        mid      == f(1.0) ==> rgt2(nil)" do

      @mid.demand.should ==  100.0
      @rgt1.demand.should == 120.0
      @rgt2.demand.should ==  0.0
    end

    it "# flexible can become negative for carrier electricity
        electricity: mid(100) == c(120) ==> rgt1(nil)
        electricity: mid      == f(1.0) ==> rgt2(nil)" do

      @mid.demand.should ==  100.0
      @rgt1.demand.should == 120.0
      @rgt2.demand.should == -20.0
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

end

