require 'spec_helper'

module Qernel::Plugins::MeritOrder
  # describe "MeritOrder" do
  #   before :all do
  #     NastyCache.instance.expire!
  #     Etsource::Base.loader('spec/fixtures/etsource')
  #   end
  # end

  describe LoadProfileTable do
    describe "#residual_load_profiles" do
      before do
        @tbl = LoadProfileTable.new(nil)
        @tbl.stub!(:graph_peak_demand).and_return(1000.0)
        dmnds = [100, 200, 300, 400]
        @tbl.stub!(:merit_order_demands).and_return(dmnds)
        @tbl.stub!(:merit_order_table).and_return([
          [0.6, [0.6, 0.00,1.00,3.0]], # 1000*0.6 - (0.6*100 + 0.0 + 1.0*300 + 3.0*400)
          [0.5, [0.7, 0.00,1.00,0.0]], # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.1*400)
          [0.5, [0.7, 0.00,1.00,0.2]], # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.1*400)
          [0.5, [0.7, 0.00,1.00,0.1]]  # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.1*400)
        ])
      end

      specify { LoadProfileTable::PRECISION.should == 10 }

      it "#residual_load_profiles" do

        @tbl.send(:residual_load_profiles).should == [
          0,
          130.0,
          50.0,
          90.0
        ]
      end

      it "#residual_ldc_coordinates" do
        points = @tbl.residual_ldc_coordinates
        points.include?([  0.0, 1.0 ]).should be_true
        points.include?([ 13.0, 0.75]).should be_true
        points.include?([ 52.0, 0.5 ]).should be_true
        points.include?([ 91.0, 0.25]).should be_true
        points.include?([130.0, 0.25]).should be_true
      end
    end
  end

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
      before  { @curve = CurveArea.new([[0.0, 10.0], [10.0, 0.0]]) }

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
      before  { @curve = CurveArea.new([[0.0, 10.0], [5.0, 4.0], [10.0, 0.0]]) }

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