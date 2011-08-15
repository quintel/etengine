require 'spec_helper'

module Gql

describe QueryInterface::Preparser do
  describe "#clean" do
    it "should remove gql-modifier (present/future/stored)" do
      str = QueryInterface::Preparser.clean("future:SUM(foo)")
      str.should == "SUM(foo)"
    end

    it "should remove gql-modifier with underscore" do
      str = QueryInterface::Preparser.clean("future_lv:SUM(foo)")
      str.should == "SUM(foo)"
    end

    it "should remove whitespace" do
      str = QueryInterface::Preparser.clean("foo bar\t\n\r\n\t baz")
      str.should == "foobarbaz"
    end

    it "should remove comments" do
      str = QueryInterface::Preparser.clean("foo/*comment*/b*a/r/*secondcomment*/baz")
      str.should == "foob*a/rbaz"
    end
  end
end

end# Gql
