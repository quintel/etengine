require "spec_helper"

describe Etsource do
  describe "local etsource" do
    it "loads the graph" do
      graph   = Etsource::Loader.instance.graph
      dataset = Etsource::Loader.instance.dataset('nl')
    end

    context "loads gql" do
      before(:all) do
        @gql = ApiScenario.default.gql(prepare: true)
        Gquery.reload_cache
        Gquery.gquery_hash
      end

      
      Gquery.gquery_hash.values.select(&:output_element?).each do |gquery|
        # only run output_elements
        
        it "runs all gquery #{gquery.key}" do
          @gql.query(gquery)
        end
        
        pending "has to verify that results are unchanged" do
          # 
        end
        
      end 
    end
  end
end