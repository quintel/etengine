require 'spec_helper'

module Gql

describe Gquery::CleanerParser do
  describe "#clean" do
    it "should remove whitespace" do
      str = Gquery::CleanerParser.clean("foo bar\t\n\r\n\t baz")
      str.should == "foobarbaz"
    end

    it "should remove comments" do
      str = Gquery::CleanerParser.clean("foo/*comment*/b*a/r/*secondcomment*/baz")
      str.should == "foob*a/rbaz"
    end
  end
end

end# Gql
