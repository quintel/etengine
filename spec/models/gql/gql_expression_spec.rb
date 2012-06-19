require 'spec_helper'

describe Gql do
  pending "Full GQL" do
    before do
      @gql = Qernel::GraphParser.gql_stubbed("lft(100) == s(1.0) ==> rgt()")
      @gql.present_graph.year = 2010
      @gql.future_graph.year = 2040
    end

    it "should return GRAPH(year)" do
      @gql.query("GRAPH(year)").present_value.should == 2010
      @gql.query("GRAPH(year)").future_value.should == 2040
    end

    it "should return present graph when running QUERY_PRESENT(GRAPH(year))" do
      Gquery.stub!('get').with('graph_year').and_return(Gquery.new(:key => 'graph_year', :query => "GRAPH(year)"))
      @gql.query("Q(graph_year)").present_value.should == 2010
      @gql.query("Q(graph_year)").future_value.should == 2040
      @gql.query("QUERY_PRESENT(graph_year)").present_value.should == 2010
      @gql.query("QUERY_PRESENT(graph_year)").future_value.should  == 2010
      @gql.query("QUERY_FUTURE(graph_year)").present_value.should  == 2040
      @gql.query("QUERY_FUTURE(graph_year)").future_value.should   == 2040
    end
  end

  pending "Tests with one graph" do # No GQL needed
    before do
      # @gql = Gql::Gql.new
      @query_interface = QueryInterface.new(nil, nil)
    end

    describe "constants" do
      before { @query = "SUM(BILLIONS)"; @result = 10.0**9 }
      specify { @query_interface.check(@query).should be_true }
      specify { @query_interface.query(@query).should be_within(@result, 10.0) }
    end
    
    def self.query_should_be_close(query, result, optional_title = nil)
      title = optional_title || "#{query} is ~= #{result}"
    
      describe optional_title do
        specify { @query_interface.check(query).should be_true }
        specify { @query_interface.query(query).should be_within(result, 10.0) }
      end
    end
    
    def self.query_should_eql(query, result, optional_title = nil)
      title = optional_title || "#{query} is ~= #{result}"
    
      describe optional_title do
        specify { @query_interface.check(query).should be_true }
        specify { @query_interface.query(query).should eql(result) }
      end
    end


    describe "arithmetic operations" do
      describe "SUM" do
        query_should_be_close("SUM(-1)", -1.0, "negative number")
        query_should_be_close "SUM(1)", 1.0
        query_should_be_close "SUM(1,2)", 3.0
        query_should_be_close "SUM(SUM(1))", 1.0, 'nested SUM'
        query_should_be_close "SUM(1,SUM(1))", 2.0, 'value and nested SUM'
      end
    
      describe "PRODUCT" do
        query_should_be_close "PRODUCT(2,3)", 6.0
      end
    
      describe "NEG" do
        query_should_be_close "NEG(1)", -1.0
        query_should_be_close "NEG(-1)", 1.0
      end
    
      describe "SQRT" do
        query_should_eql "SQRT(4)", [2.0]
        query_should_eql "SQRT(4,9)", [2.0,3.0]
      end
    
      pending "NORMCDF" do
        query_should_be_close "NORMCDF(-0.2, 0, 1)", 0.42072
        query_should_be_close "NORMCDF(0.2,  0,  1)", 0.57926
        query_should_be_close "NORMCDF(8, 10,  2)", 0.15866
        query_should_be_close "NORMCDF(500,450, 50)",  0.84134
        query_should_be_close "NORMCDF(200,450, 50)",  0.00003 
        query_should_be_close "NORMCDF(19.9, 22.9, 1)",  0.0013499
        query_should_be_close "NORMCDF(0, 0, 1)",  0.5
        #query_should_be_close "NORMCDF(0.5, 0, 0)", nil
      end
    end
  end
end