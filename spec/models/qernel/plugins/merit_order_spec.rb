require 'spec_helper'

module Qernel::Plugins::MeritOrder
  describe "MeritOrder" do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    # Stubs methods for the etsource fixture, so that merit order runs properly
    def stubbed_gql
      Scenario.default.gql do |gql|
        gql.future_graph[:use_merit_order_demands] = 1
      end
    end

    context "fixtures default scenario" do
      pending "triggers the merit order calculation" do
        MeritOrderBreakpoint.any_instance.should_receive(:setup).and_return(true)
        gql = stubbed_gql
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
    end
  end
end
