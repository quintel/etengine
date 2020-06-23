require 'spec_helper'

module Qernel
  describe Node do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    describe "max_demand_recursive" do
      before do
        @gql = Scenario.default.gql
      end

      it "equals max_demand if max_demand is available"  do
        expect(@gql.query_future("V(max_demand_node_b, max_demand)")).to eq(6000.0)
        expect(@gql.query_future("V(max_demand_node_b, max_demand_recursive)")).to eq(6000.0)
        expect(@gql.query_future("V(max_demand_node_c, max_demand)")).to eq(500.0)
        expect(@gql.query_future("V(max_demand_node_c, max_demand_recursive)")).to eq(500.0)
      end

      it "uses max_demand / share of the node that has minimum share * max_demand" do
        expect(@gql.query_future("V(max_demand_node_a, max_demand)")).to eq(5000.0)
        expect(@gql.query_future("V(max_demand_node_a, max_demand_recursive)")).to eq(5000.0)
      end

      it "works with one edge" do
        expect(@gql.query_future("V(max_demand_node_d, max_demand)")).to eq(5000.0)
      end

      it "the max_demand actually works" do
        expect(@gql.query_future("V(max_demand_node_with_high_demand_remainder, demand)")).to eq(5000.0)
      end
    end

    describe "max_demand_recursive with different numbers" do
      before do
        @gql = Scenario.default.gql(prepare: false)
        @gql.init_datasets
        @gql.future_graph.node(:max_demand_node_b).output_edges.first.share = 0.99
        @gql.future_graph.node(:max_demand_node_c).output_edges.first.share = 0.01
        @gql.update_graphs
        @gql.calculate_graphs
      end

      it "equals max_demand if max_demand is available"  do
        expect(@gql.query_future("V(max_demand_node_b, max_demand)")).to eq(6000.0)
        expect(@gql.query_future("V(max_demand_node_b, max_demand_recursive)")).to eq(6000.0)
        expect(@gql.query_future("V(max_demand_node_c, max_demand)")).to eq(500.0)
        expect(@gql.query_future("V(max_demand_node_c, max_demand_recursive)")).to eq(500.0)
      end

      it "uses max_demand / share of the node that has minimum share * max_demand" do
        expect(@gql.query_future("V(max_demand_node_a, max_demand)").floor).to  eq(6060)
        expect(@gql.query_future("V(max_demand_node_a, max_demand_recursive)").floor).to eq(6060)
      end

      it "works with one edge" do
        expect(@gql.query_future("V(max_demand_node_d, max_demand)").floor).to  eq(6060)
      end

      it "the max_demand actually works" do
        expect(@gql.query_future("V(max_demand_node_with_high_demand_remainder, demand)").ceil).to eq(3940)
      end
    end
  end
end
