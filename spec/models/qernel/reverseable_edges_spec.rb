require 'spec_helper'

describe "Reversed Edges" do
  describe "reversed edges" do
    before do
      @gql = Scenario.default.gql
    end

    it "updates the flexible demand when preset_demand is given" do
      # assert correct assignment
      expect(@gql.query_present("V(reversed_edges_left,     demand)")).to eq(1500.0)
      expect(@gql.query_present("V(reversed_edges_middle_1, demand)")).to eq(1000.0)
      expect(@gql.query_present("V(reversed_edges_middle_3, demand)")).to eq(100.0)

      expect(@gql.query_present("V(reversed_edges_middle_2, demand)")).to eq(400.0)
    end

    it "updates the flexible demand when preset_demand is nil" do
      gql = Scenario.default.gql do |gql|
        gql.future_graph.node(:reversed_edges_left).preset_demand = nil
      end

      expect(gql.query_future("V(reversed_edges_left,     demand)")).to eq(1100.0)
      expect(gql.query_future("V(reversed_edges_middle_2, demand)")).to eq(0.0)
    end

  end
end
