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
        expect(@gql.query_present("QUERY_FUTURE(  -> { GRAPH(year) } )")).to eq(2040)
        expect(@gql.query_future( "QUERY_FUTURE(  -> { GRAPH(year) } )")).to eq(2040)

        expect(@gql.query_future( "QUERY_DELTA(  -> { GRAPH(year) } )")).to eq(29)
      end

      it "QUERY_DELTA for the present should always return 0.0" do
        expect(@gql.query_present("QUERY_DELTA( bar_demand )")).to eq(0.0)
        expect(@gql.query_present("QUERY_DELTA(  -> { GRAPH(year) } )")).to eq(0.0)
      end

      describe 'TIME_CURVE' do
        describe 'when the curve and attribute exist' do
          let(:curve) { @gql.query_present("TIME_CURVE(coal, preset_demand)") }

          it 'returns a hash' do
            expect(curve).to be_a(Hash)
          end

          it 'includes the values' do
            expect(curve).to_not be_empty
          end

          it 'converts the values from GJ to PJ' do
            # Value in the CSV is 4.925e5
            expect(curve[2010]).to eq(0.4925)
          end
        end

        it 'raises an error when the curve exists, but the attr does not' do
          expect {
            @gql.query_present("TIME_CURVE(coal, nope)")
          }.to raise_error(/no attribute named/i)
        end

        it 'raises an error when the curve does not exist' do
          expect {
            @gql.query_present("TIME_CURVE(nope, preset_demand)")
          }.to raise_error(/no such time curve/i)
        end
      end
    end

  end
end
