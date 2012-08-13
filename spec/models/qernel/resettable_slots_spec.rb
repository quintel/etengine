require 'spec_helper'

module Qernel
  describe Converter do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    describe "max_demand_recursive" do
      before do 
        @gql = Scenario.default.gql
      end

      it "equals max_demand if max_demand is available"  do
        @gql.query_future("V(resettable_slots_with_hidden_link, demand)").should == 11000.0
        @gql.query_future("V(resettable_slots_with_hidden_link_child, demand)").should == 11000.0
        @gql.query_future("V(resettable_slots_with_hidden_link_child, primary_demand)").should == 11000.0
        @gql.future_graph.converter(:resettable_slots_with_hidden_link_child).primary_energy_demand?.should be_true
        @gql.query_future("V(resettable_slots_with_reset_slot, primary_demand)").should == 0.0
        @gql.query_future("V(resettable_slots_with_hidden_link, primary_demand)").should == 11000.0
      end
    end
  end
end
