require 'spec_helper'

module Gql
  describe Runtime do
    before :all do
      NastyCache.instance.expire!
      Etsource::Base.loader('spec/fixtures/etsource')
    end

    describe "QUERY_FUTURE/PRESENT/DELTA" do
      before do
        @gql = Scenario.default.gql(prepare: true)
      end

      it "should work when passing keys" do
        @gql.query_present("QUERY_PRESENT( bar_demand )").should == 60.0
        @gql.query_future( "QUERY_PRESENT( bar_demand )").should == 60.0
        @gql.query_present("QUERY_FUTURE(  bar_demand )").should == 60.0
        @gql.query_future( "QUERY_FUTURE(  bar_demand )").should == 60.0
      end

      it "should work when passing procs" do
        @gql.query_present("QUERY_PRESENT( -> { GRAPH(year) } )").should == 2010
        @gql.query_future( "QUERY_PRESENT( -> { GRAPH(year) } )").should == 2010
        @gql.query_present("QUERY_FUTURE(  -> { GRAPH(year) } )").should == 2040
        @gql.query_future( "QUERY_FUTURE(  -> { GRAPH(year) } )").should == 2040


        @gql.query_present("QUERY_DELTA(  -> { GRAPH(year) } )").should == 30
        @gql.query_future( "QUERY_DELTA(  -> { GRAPH(year) } )").should == 30
      end
    end

  end
end