require 'spec_helper'

describe ApiRequest do

  describe "#new" do
    it "should assign settings" do
      ApiRequest.new(:settings => :foo).settings.should == :foo
    end

    it ":id => 'test' => test_scenario?" do
      ApiRequest.new(:id => 'test').should be_test_scenario
    end

    it "should assign :r" do
      keys = %w[foo bar]
      ApiRequest.new(:r => keys.join(ApiRequest::GQUERY_KEY_SEPARATOR)).gquery_keys.should == keys
    end

    it "should assign :results" do
      keys = %w[foo bar]
      ApiRequest.new(:results => keys).gquery_keys.should == keys
    end

    it "should assign :r and :results" do
      keys = %w[foo bar]
      ApiRequest.new(
        :results => keys,
        :r => %w[baz moo].join(ApiRequest::GQUERY_KEY_SEPARATOR)
      ).gquery_keys.sort.should == %w[foo bar baz moo].sort
    end

  end
end




