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
        @graph = @gql.future_graph
        @converter_a = @graph.converter(:max_demand_converter_a)
        @converter_b = @graph.converter(:max_demand_converter_b)
        @converter_c = @graph.converter(:max_demand_converter_c)
      end

      it "equals max_demand if max_demand is available"  do
        @gql.query_future("V(max_demand_converter_b, max_demand)").should == 6000.0
        @gql.query_future("V(max_demand_converter_b, max_demand_recursive)").should == 6000.0
        @gql.query_future("V(max_demand_converter_c, max_demand)").should == 500.0
        @gql.query_future("V(max_demand_converter_c, max_demand_recursive)").should == 500.0
      end

      it "uses max_demand / share of the converter that has minimum share * max_demand" do
        @gql.query_future("V(max_demand_converter_a, max_demand)").should == 5000.0
        @gql.query_future("V(max_demand_converter_a, max_demand_recursive)").should == 5000.0        
      end

      it "works with one link" do
        @gql.query_future("V(max_demand_converter_d, max_demand)").should == 5000.0
      end
    end
  end
end