# frozen_string_literal: true

require 'spec_helper'

module Gql
  describe Runtime, :etsource_fixture do
    describe "QUERY_FUTURE/PRESENT/DELTA" do
      before do
        @gql = Scenario.default.gql(prepare: true)
      end

      it "should work when passing keys" do
        expect(@gql.query_present("QUERY_PRESENT( bar_demand )")).to eq(60.0)
        expect(@gql.query_future( "QUERY_PRESENT( bar_demand )")).to eq(60.0)
        expect(@gql.query_present("QUERY_FUTURE(  bar_demand )")).to eq(60.0)
        expect(@gql.query_future( "QUERY_FUTURE(  bar_demand )")).to eq(60.0)
      end

      it "should work when passing procs" do
        expect(@gql.query_present("QUERY_PRESENT( -> { GRAPH(year) } )")).to eq(2011)
        expect(@gql.query_future( "QUERY_PRESENT( -> { GRAPH(year) } )")).to eq(2011)
        expect(@gql.query_present("QUERY_FUTURE(  -> { GRAPH(year) } )")).to eq(2050)
        expect(@gql.query_future( "QUERY_FUTURE(  -> { GRAPH(year) } )")).to eq(2050)

        expect(@gql.query_future( "QUERY_DELTA(  -> { GRAPH(year) } )")).to eq(39)
      end

      it "QUERY_DELTA for the present should always return 0.0" do
        expect(@gql.query_present("QUERY_DELTA( bar_demand )")).to eq(0.0)
        expect(@gql.query_present("QUERY_DELTA(  -> { GRAPH(year) } )")).to eq(0.0)
      end
    end
  end
end
