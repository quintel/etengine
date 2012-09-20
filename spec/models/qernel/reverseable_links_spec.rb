require 'spec_helper'

describe "Reversed Links" do
  before :all do
    NastyCache.instance.expire!
    Etsource::Base.loader('spec/fixtures/etsource')
  end

  describe "reversed links" do
    before :all do
      @gql = Scenario.default.gql
    end

    it "updates the flexible demand when preset_demand is given" do
      # assert correct assignment
      @gql.query_present("V(reversed_links_left,     demand)").should == 1500.0
      @gql.query_present("V(reversed_links_middle_1, demand)").should == 1000.0
      @gql.query_present("V(reversed_links_middle_3, demand)").should ==  100.0

      @gql.query_present("V(reversed_links_middle_2, demand)").should ==  400.0
    end

    it "updates the flexible demand when preset_demand is nil" do
      gql = Scenario.default.gql do |gql|
        gql.future_graph.converter(:reversed_links_left).preset_demand = nil
      end

      gql.query_future("V(reversed_links_left,     demand)").should == 1100.0
      gql.query_future("V(reversed_links_middle_2, demand)").should ==  0.0
    end

  end
end
