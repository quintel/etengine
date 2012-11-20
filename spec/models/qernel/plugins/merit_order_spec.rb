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

      pending "should correctly count positions" do
        @converters[0].query.merit_order_position.should == 1
        @converters[1].query.merit_order_position.should == 1000 # 0   => 1000
        @converters[2].query.merit_order_position.should == 1000 # nil => 1000
        @converters[3].query.merit_order_position.should == 2
      end
    end
  end
end
