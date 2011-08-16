require 'spec_helper'

module Gql

describe QueryInterface::Preparser do
  describe "#clean" do
    it "should remove gql-modifier (present/future/stored)" do
      str = QueryInterface::Preparser.new("future:SUM(foo)").clean
      str.should == "SUM(foo)"
    end

    it "should remove gql-modifier with underscore" do
      str = QueryInterface::Preparser.new("future_lv:SUM(foo)").clean
      str.should == "SUM(foo)"
    end

    it "should remove whitespace" do
      str = QueryInterface::Preparser.new("foo bar\t\n\r\n\t baz").clean
      str.should == "foobarbaz"
    end

    it "should remove comments" do
      str = QueryInterface::Preparser.new("foo/*comment*/b*a/r/*secondcomment*/baz").clean
      str.should == "foob*a/rbaz"
    end
  end
end

end# Gql
