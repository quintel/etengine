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
    end

    # ----- Mutliple carriers ------------------------------------------------

    # it "hw: lft(100) [0.5]== s(1.0) ==> rgt1 
    #           el: lft      [0.5]== s(1.0) ==> rgt2" do
    # 
    #   @g.converter(:rgt1).demand.should == 50.0
    #   @g.converter(:rgt2).demand.should == 50.0
    # end

    # ----- Share only ------------------------------------------------

    it "lft(100) == s(0.3) ==> rgt1(nil)
        lft      == s(0.7) ==> rgt2(nil)" do

      @g.converter(:rgt1).demand.should == 30.0
      @g.converter(:rgt2).demand.should == 70.0
    end

    # ----- Constant ------------------------------------------------

    it "mid(nil) == c(30) ==> rgt1 
        mid      == c(20) ==> rgt2" do

      @g.converter(:mid).demand.should ==  0.0 
      @g.converter(:rgt1).demand.should == 30.0 
      @g.converter(:rgt2).demand.should == 20.0 
    end

    it "mid(nil) == c(nil) ==> rgt1(80) 
        mid      == c(nil) ==> rgt2(20)" do

      @g.converter(:mid).demand.should == 100.0 
      @g.converter(:rgt1).demand.should == 80.0 
      @g.converter(:rgt2).demand.should == 20.0 
    end

    # ----- Flexible & Share  --------------------------------------

    it "mid(100) == s(0.8) ==> rgt1(nil) 
        mid      == f(1.0) ==> rgt2(nil)" do

      @g.converter(:rgt1).demand.should == 80.0
      @g.converter(:rgt2).demand.should == 20.0 
    end

    # ----- Flexible & Constant  --------------------------------------

    it "# If mid has no output link, it becomes 0.0
        mid(nil) == c(80)  ==> rgt1(nil) 
        mid      == f(1.0) ==> rgt2(nil)" do

      @g.converter(:mid).demand.should == 0.0
      @g.converter(:rgt1).demand.should == 80.0
      @g.converter(:rgt2).demand.should == 0.0
    end

    it "# This works, because mid gets demand from lft
        lft(100) == s(1)  ==> mid(nil)
        mid(nil) == c(80) ==> rgt1(nil) 
        mid      == f(1)  ==> rgt2(nil)" do

      @g.converter(:lft).demand.should ==  100.0
      @g.converter(:mid).demand.should ==  100.0
      @g.converter(:rgt1).demand.should == 80.0
      @g.converter(:rgt2).demand.should == 20.0
    end

    it "# if constant share is nil, assign right demand to the mid
        mid(nil) == c(nil) ==> rgt1(80)
        mid      == f(1.0) ==> rgt2(nil)" do

      @g.converter(:mid).demand.should ==  80.0
      @g.converter(:rgt1).demand.should == 80.0
      @g.converter(:rgt2).demand.should ==  0.0
    end

    # ----- Inversed Flexible  --------------------------------------

    it "# mid assigned 100 from lft1 fills up l
        loss(nil) == i(1)  ==> mid(nil)
        lft1(100) == s(1)   ==> mid
        mid       == c(nil) ==> rgt1(40) 
        mid       == f(nil) ==> rgt2(30)" do
    
      @g.converter(:lft1).demand.should == 100.0
      @g.converter(:mid).demand.should ==  100.0
      @g.converter(:rgt1).demand.should == 40.0
      @g.converter(:rgt2).demand.should == 30.0
      @g.converter(:loss).demand.should ==  30.0
    end

  end

end

