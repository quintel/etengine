require "spec_helper"

describe Etsource do
  describe "local etsource" do
    it "loads the graph" do
      graph   = Etsource::Loader.instance.graph
      dataset = Etsource::Loader.instance.dataset('nl')
    end

    pending "loads gql" do
      before(:all) do
        @gql = Scenario.default.gql(prepare: true)
      end


      Gquery.all.select(&:output_element?).each do |gquery|
        # only run output_elements
        it "runs all gquery #{gquery.key}" do
          @gql.query(gquery)
        end
      end
    end
  end
end
