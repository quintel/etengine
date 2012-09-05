require 'spec_helper'

module Qernel::Plugins::MeritOrder
  # describe "MeritOrder" do
  #   before :all do
  #     NastyCache.instance.expire!
  #     Etsource::Base.loader('spec/fixtures/etsource')
  #   end
  # end

  describe CurveArea do

    # 10 *
    #    |  *
    #    |     *
    #  5 |        *
    #    |           *
    #    |              *
    #    +------------------*
    #            5         10
    #       total area: 50
    #
    context "curve with a simple slope" do
      before { @curve = CurveArea.new([[0.0, 10.0], [10.0, 0.0]]) }

      specify { @curve.area(0,   10.0).should == 50.0 } # total area
      specify { @curve.area(5.0, 10.0).should == 12.5 } # 5 * 5 / 2
      specify { @curve.area(5.0,  5.0).should ==  0.0 } # area of same x = 0

      it "Consequent areas sum up to 50.0" do
        [
          @curve.area(  0,  1.0),
          @curve.area(1.0,  4.0),
          @curve.area(4.0, 10.0)
        ].inject(:+).should == 50.0
      end
    end

    # 10 *
    #    | *
    #    |   *
    #    |     *
    #  4 |       *
    #    |            *
    #    +------------------*
    #            5         10
    #       35   +   10 => 45 total area
    #
    context "curve with a simple slope" do
      before { @curve = CurveArea.new([[0.0, 10.0], [5.0, 4.0], [10.0, 0.0]]) }

      specify { @curve.area(0.0,  5.0).should == 35 }
      specify { @curve.area(5.0, 10.0).should == 10 }

      it "Calculates correctly across points:" do
        @curve.area(0.0, 10.0).should == 45
      end

      it "Consequent areas sum up to 50.0" do
        [
          @curve.area(  0,  1.0),
          @curve.area(1.0,  4.0),
          @curve.area(4.0,  6.0), # crossing a point
          @curve.area(6.0, 10.0)
        ].inject(:+).round(1).should == 45
      end
    end
  end
end