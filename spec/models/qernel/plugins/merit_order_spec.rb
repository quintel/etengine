require 'spec_helper'

module Qernel::Plugins::MeritOrder
  describe "MeritOrder" do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
      Qernel::ConverterApi.create_methods_for_each_carrier([:electricity])
    end

    # Stubs methods for the etsource fixture, so that merit order runs properly
    def stubbed_gql
      Scenario.default.gql do |gql|
        gql.future_graph[:use_merit_order_demands] = 1
        # make first converters more expensive. So their merit_order_position moves backwards
        # typical_electricity_output needed for variable_costs
        # Default of 500.0 for installed_production_capacity_in_mw_electricity needed for the merit_order calculation
        gql.future_graph.dispatchable_merit_order_converters.sort_by(&:key).each_with_index do |converter, idx|
          converter.query.stub!(:variable_costs).and_return(10.0 - idx)
          converter.query.stub!(:typical_electricity_output).and_return(1.0)
          converter.query.stub!(:installed_production_capacity_in_mw_electricity).and_return(500.0)

          converter.query.stub!(:full_load_seconds).and_return(100.0)
          converter.query.stub!(:typical_nominal_input_capacity).and_return(1.0)
          converter.query.stub!(:number_of_units).and_return(1.0)

          yield converter, idx if block_given?
        end
      end
    end

    context "fixtures default scenario" do
      pending "works correctly with breakpoints." do
        # Sort converters randomly, to check that calculation respects breakpoints.
        gql = Scenario.default.gql do |gql|
          gql.future_graph[:use_merit_order_demands] = 1
          gql.future_graph.converters.sort_by!{rand}
        end

        finished = gql.future_graph.finished_converters.map(&:key)
        finished.last.should == :import_electricity

        # plants are calculated before grid and overflowing import_electricity. But after
        # all other converters were calculated.
        finished.index(:plant_1).should < finished.index(:el_grid)
        finished.index(:plant_1).should < finished.index(:import_electricity)
        finished.index(:plant_2).should < finished.index(:import_electricity)
        finished.index(:must_run_1).should < finished.index(:plant_1)
        finished.index(:must_run_2).should < finished.index(:plant_1)
      end


      pending "MO updates demand and calculates correctly reversed links and fills up remaining flex" do
        gql = stubbed_gql

        gql.query_future("V(el_grid, demand)").should == 5000
        gql.query_future("V(plant_1, demand)").should == 100
        gql.query_future("V(plant_2, demand)").should == 100
        gql.query_future("V(import_electricity, demand)").should == 4800
      end

      pending "with misisng attrs/methods assigns merit_order_position 1000" do
        gql = Scenario.default.gql do |gql|
          gql.future_graph[:use_merit_order_demands] = 1
        end
        gql.query_future("V(plant_1, merit_order_position)").should == 1000
        gql.query_future("V(plant_2, merit_order_position)").should == 1000
      end

      pending "with stubbed attrs/methods assigns merit_order as expected" do
        gql = stubbed_gql

        gql.query_future("V(plant_1, merit_order_position)").should == 2
        gql.query_future("V(plant_1, merit_order_end)").should      == 1000.0
        gql.query_future("V(plant_2, merit_order_position)").should == 1

        gql.query_future("V(plant_2, merit_order_position)").should == 1
        gql.query_future("V(plant_2, merit_order_start)").should    == 0.0
        gql.query_future("V(plant_2, merit_order_end)").should      == 500.0
      end

      pending "takes into account availability" do
        gql = stubbed_gql do |converter, idx|
          converter.query.stub!(:availability).and_return( 0.5 )
        end

        gql.query_future("V(plant_1, merit_order_end)").should      == 500.0
        gql.query_future("V(plant_2, merit_order_end)").should      == 250.0
      end

      pending "takes into account availability" do
        gql = stubbed_gql do |converter, idx|
          converter.query.stub!(:availability).and_return( 0.5 )
        end

        gql.query_future("V(plant_1, merit_order_end)").should      == 500.0
        gql.query_future("V(plant_2, merit_order_end)").should      == 250.0
      end
    end

    describe "#calculate_merit_order" do
      before do
        @graph = Scenario.default.gql.future_graph

        # Take some random converters and assign them required variables
        @converters = @graph.converters[0...4]

        # The following numbers define how the merit_order attributes are assigned.
        [50, 0, nil, 200].each_with_index do |inst_cap, i|
          @converters[i].query.stub!(:installed_production_capacity_in_mw_electricity).and_return inst_cap
          @converters[i].query.stub!(:availability).and_return 1.0
        end

        @graph.stub!(:dispatchable_merit_order_converters).and_return(@converters)
        @graph.stub!(:converters_by_total_variable_cost).and_return(@converters.map(&:query))
        Qernel::Plugins::MeritOrder::MeritOrderBreakpoint.new(@graph).run
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
        @calc = Qernel::Plugins::MeritOrder::MeritOrderBreakpoint.new(@graph)
      end

      #
      it "if it covers the whole area (roughly only half capacity)" do
        @converter.merit_order_end = 14000

        @ldc_polygon.area(0, 14000).should == 7206.8

        { # availability, expected capacity_factor
          1.0 => 0.5,
          0.8 => 0.4,
          0.5 => 0.3,
          0.1 => 0.1
        }.each do |availability, capacity_factor|
          @converter.availability = availability
          @calc.capacity_factor_for(@converter, @ldc_polygon).round(1).should == capacity_factor
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
          @calc.capacity_factor_for(@converter, @ldc_polygon).round(1).should == capacity_factor
        end
      end
    end
  end

  describe LoadProfileTable do
    describe "#residual_load_profiles" do
      before do
        @tbl = LoadProfileTable.new(nil)
        @tbl.stub!(:graph_electricity_demand).and_return(1000.0)
        # Stubbing all this is unsexy, but it gives a good overview how the
        # calculations fit together.
        @tbl.stub!(:merit_order_table).and_return([
          [0.6, [0.6, 0.00,1.00,3.0]], # 1000*0.6 - (0.6*100 + 0.0 + 1.0*300 + 3.0*400)
          [0.5, [0.7, 0.00,1.00,0.0]], # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.0*400)
          [0.5, [0.7, 0.00,1.00,0.2]], # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.2*400)
          [0.5, [0.7, 0.00,1.00,0.1]]  # 1000*0.5 - (0.7*100 + 0.0 + 1.0*300 + 0.1*400)
        ])
        # demands calculated by the graph for the defined groups of converters.
        dmnds = [100, 200, 300, 400]
        @tbl.stub!(:merit_order_must_run_production).and_return(dmnds)
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
