require 'spec_helper'

describe Gquery do
  describe "#gql_modifier" do
    it "should return gql_modifier if existant in query" do
      gquery = Gquery.new(:query => "future:SUM(1,1)")
      expect(gquery.gql_modifier).to eq('future')
    end

    it "should return nil if not exists in query" do
      gquery = Gquery.new(:query => "SUM(1,1)")
      expect(gquery.gql_modifier).to eq(nil)
    end
  end
end

