require 'spec_helper'

describe Gquery do
  describe "#gql_modifier" do
    it "should return gql_modifier if existant in query" do
      gquery = Gquery.new(:query => "future:SUM(1,1)")
      gquery.gql_modifier.should == 'future'
    end

    it "should return nil if not exists in query" do
      gquery = Gquery.new(:query => "SUM(1,1)")
      gquery.gql_modifier.should == nil
    end
  end

  describe "#new" do
    it "should remove whitespace from key" do
      gquery = Gquery.new(:key => " foo \t ", :query => "SUM(1,1)")
      gquery.key.should == 'foo'
    end
  end

  it "should be valid'" do
    Gquery.new(:key => 'foo_bar_new', :query => 'SUM(1,1)').should be_valid
  end

  it "should not be valid with keys 'null' and 'undefined'" do
    Gquery.new(:key => 'null', :query => 'SUM(1,1)').should_not be_valid
    Gquery.new(:key => 'undefined', :query => 'SUM(1,1)').should_not be_valid
  end

end

