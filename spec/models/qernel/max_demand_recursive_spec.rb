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

    describe "max_demand_recursive with different numbers" do
      before do 
        @gql = Scenario.default.gql(prepare: false)
        @gql.init_datasets
        @gql.future_graph.converter(:max_demand_converter_b).output_links.first.share = 0.99
        @gql.future_graph.converter(:max_demand_converter_c).output_links.first.share = 0.01
        @gql.update_graphs
        @gql.calculate_graphs
      end

      it "equals max_demand if max_demand is available"  do
        @gql.query_future("V(max_demand_converter_b, max_demand)").should == 6000.0
        @gql.query_future("V(max_demand_converter_b, max_demand_recursive)").should == 6000.0
        @gql.query_future("V(max_demand_converter_c, max_demand)").should == 500.0
        @gql.query_future("V(max_demand_converter_c, max_demand_recursive)").should == 500.0
      end

      it "uses max_demand / share of the converter that has minimum share * max_demand" do
        @gql.query_future("V(max_demand_converter_a, max_demand)").to_i.should  == 6060
        @gql.query_future("V(max_demand_converter_a, max_demand_recursive)").to_i.should == 6060
      end

      it "works with one link" do
        @gql.query_future("V(max_demand_converter_d, max_demand)").to_i.should  == 6060
      end
    end
  end
end