require 'spec_helper'

module Qernel::Plugins::MeritOrder
  describe "MeritOrder" do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    describe "#calculate_merit_order" do
      before do
        @graph = Scenario.default.gql.future_graph

        # Take some random converters and assign them required variables
        @converters = @graph.converters[0...4]
        [50, 0, nil, 200].each_with_index do |inst_cap, i|
          @converters[i].query.stub!(:installed_production_capacity_in_mw_electricity).and_return inst_cap
          @converters[i].query.stub!(:availability).and_return 1.0
        end

        @graph.stub!(:dispatchable_merit_order_converters).and_return(@converters)
        @graph.stub!(:converters_by_total_variable_cost).and_return(@converters.map(&:query))
        @graph.calculate_merit_order
      end

      it "should correctly sum merit_order_start" do
        @converters[0].query.merit_order_start.should ==  0
        @converters[1].query.merit_order_start.should == 50
        @converters[2].query.merit_order_start.should == 50
        @converters[3].query.merit_order_start.should == 50
      end

      it "should correctly sum merit_order_end" do
        @converters[0].query.merit_order_end.should ==  50
        @converters[1].query.merit_order_end.should ==  50
        @converters[2].query.merit_order_end.should ==  50
        @converters[3].query.merit_order_end.should == 250
      end

      it "should correctly count positions" do
        @converters[0].query.merit_order_position.should == 1
        @converters[1].query.merit_order_position.should == 1000 # 0   => 1000
        @converters[2].query.merit_order_position.should == 1000 # nil => 1000
        @converters[3].query.merit_order_position.should == 2
      end
    end

    describe "#capacity_factor_for" do
      before do
        @graph = Scenario.default.gql.future_graph
        # The following is a realistic curve taken from etm
        @ldc_polygon = CurveArea.new([[0.0, 1.0], [1402, 1.0], [7014, 0.5], [12000, 0.1], [14000, 0.0]])
        @converter = @graph.converters.first.query
        @converter.merit_order_start = 0.0
      end

      it "if it covers the whole area" do
        @converter.merit_order_end = 14000
        @ldc_polygon.area(0, 14000).should == 7206.8

        {
          1.0 => 0.5,
          0.8 => 0.4,
          0.5 => 0.3,
          0.1 => 0.1
        }.each do |availability, capacity_factor|
          @converter.availability = availability
          @graph.capacity_factor_for(@converter, @ldc_polygon).round(1).should == capacity_factor
        end
      end

      it "if it covers only the first part (full capacity) availability becomes capacity_factor" do
        @converter.merit_order_end = 1402
        @ldc_polygon.area(0, @converter.merit_order_end).should == 1402

        { # availability, expected capacity_factor
          1.0 => 1.0,
          0.8 => 0.8,
          0.5 => 0.5,
          0.1 => 0.1
        }.each do |availability, capacity_factor|
          @converter.availability = availability
          @graph.capacity_factor_for(@converter, @ldc_polygon).round(1).should == capacity_factor
        end
      end
    end
  end

  describe LoadProfileTable do
    describe "#residual_load_profiles" do
      before do
        @tbl = LoadProfileTable.new(nil)
        @tbl.stub!(:graph_peak_power).and_return(1000.0)
        # Stubbing all this is unsexy, but it gives a good overview how the
        # calculations fit together.
        @tbl.stub!(:merit_order_table).and_return([
          [0.6, [0.6, 0.00,1.00,3.0]], # 1000*0.6 - (0.6*100 + 0.0 + 1.0*300 + 3.0*400)
          [0.5, [0.7, 0.00,1.00,0.0]], # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.1*400)
          [0.5, [0.7, 0.00,1.00,0.2]], # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.1*400)
          [0.5, [0.7, 0.00,1.00,0.1]]  # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.1*400)
        ])
        # demands calculated by the graph for the defined groups of converters.
        dmnds = [100, 200, 300, 400]
        @tbl.stub!(:merit_order_must_run_loads).and_return(dmnds)
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
        [ # expected coordinates
          [  0.0, 1.0 ],
          [ 13.0, 0.75],
          [ 52.0, 0.5 ],
          [ 91.0, 0.25],
          [130.0, 0.25]
        ].each do |coordinate|
          points.include?(coordinate).should be_true
        end

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
    context "curve with a 2 point slope" do
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
    context "curve with a 3 point slope" do
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
