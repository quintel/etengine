require 'spec_helper'

module Gql

describe QueryInterface do
  before do
    @query_interface = QueryInterface.new(nil)
    Current.instance.stub_chain(:gql, :calculated?).and_return(true)
  end

  describe "traversing" do
    before do
      @graph = Qernel::GraphParser.new("
        lft(100) == c(1.0) ==> rgt
        mid(100) == s(1.0) ==> rgt
      ").build
      Current.instance.stub_chain(:gql, :calculated?).and_return(true)
      @q = QueryInterface.new(@graph)
    end

    pending "BUG: LINKS" do
      @q.query("OUTPUT_LINKS(V(lft))").length.should == 0
    end

    it "LINKS" do
      @q.query("INPUT_LINKS(V(lft))").length.should == 1
      @q.query("INPUT_LINKS(V(lft);constant)").length.should == 1
      @q.query("INPUT_LINKS(V(lft);is_share)").length.should == 0
      @q.query("INPUT_LINKS(V(lft,mid);is_share)").length.should == 1
      @q.query("INPUT_LINKS(V(lft,mid))").length.should == 2
      @q.query("OUTPUT_LINKS(V(rgt))").length.should == 2
    end
  end

  describe "constants" do
    before { @query = "SUM(BILLIONS)"; @result = 10.0**9 }
    specify { @query_interface.check(@query).should be_true }
    specify { @query_interface.query(@query).should be_near(@result) }
  end

  def self.query_should_be_close(query, result, optional_title = nil)
    title = optional_title || "#{query} is ~= #{result}"

    describe optional_title do
      specify { @query_interface.check(query).should be_true }
      specify { @query_interface.query(query).should be_near(result) }
    end
  end

  def self.query_should_eql(query, result, optional_title = nil)
    title = optional_title || "#{query} is ~= #{result}"

    describe optional_title do
      specify { @query_interface.check(query).should be_true }
      specify { @query_interface.query(query).should eql(result) }
    end
  end



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

  describe "AREA" do
    before {@query_interface.stub!(:area).with('foo').and_return(5.0)}
    query_should_be_close "AREA(foo)", 5.0
  end

  describe "GRAPH" do
    before {@query_interface.stub!(:graph_query).with('foo').and_return(5.0)}
    query_should_be_close "GRAPH(foo)", 5.0
  end

  describe "QUERY" do
    describe "subqueries" do
      before {@query_interface.stub!(:subquery).with('foo').and_return(5.0)}
      query_should_be_close "QUERY(foo)", 5.0
    end
  end

  describe "INVALID_TO_ZERO" do
    describe "basic values" do
      before { @query = "INVALID_TO_ZERO(1,DIVIDE(0,0))"; }
      subject { @query_interface.query(@query) }
      its(:first) { should be_near(1.0) }
      its(:last)  { should be_near(0.0) }
    end

    describe "between VALUE" do
      before { @query = "INVALID_TO_ZERO(V(1,DIVIDE(0,0)))"; }
      subject { @query_interface.query(@query) }
      its(:first) { should be_near(1.0) }
      its(:last)  { should be_near(0.0) }
    end
  end

  describe "converters" do
    before do
      # We cannot mock easily Converters using mock('Converter', :demand => 1)
      # Because Array#flatten calls to_ary on every object within an array - and we 
      # use flatten a lot in GQL queries. I haven't found a way to easily do that with a mock. (sb)
      @c1 = Qernel::Converter.new(1, 'foo')
      @c2 = Qernel::Converter.new(2, 'bar')
      @c3 = Qernel::Converter.new(3, 'baz')

      @c1.stub!(:demand).and_return(1.0)
      @c2.stub!(:demand).and_return(2.0)
      @c3.stub!(:demand).and_return(3.0)
      @c1.query.stub!(:demand).and_return(1.0)
      @c2.query.stub!(:demand).and_return(2.0)
      @c3.query.stub!(:demand).and_return(3.0)

      @query_interface.stub!(:converters).and_return([@c1,@c2,@c3])
      @query_interface.stub!(:group_converters).with(['foo']).and_return([@c1,@c2])
      @query_interface.stub!(:group_converters).with(['bar']).and_return([@c2,@c3])
    end

    describe "GROUP" do
      before { @query = "GROUP(foo)"; @result = [@c1,@c2] }
      specify { @query_interface.check(@query).should be_true }
      specify { @query_interface.query(@query).should eql(@result) }
    end

    describe "INTERSECTION" do
      before { @query = "INTERSECTION(GROUP(foo),GROUP(bar))"; @result = [@c2] }
      specify { @query_interface.check(@query).should be_true }
      specify { @query_interface.query(@query).should eql(@result) }
    end

    describe "VALUE" do
      describe "multiple converters" do
        before { @query = "SUM(VALUE(ca,cb,cd;demand))"; @result = 6.0 }
        specify { @query_interface.check(@query).should be_true }
        specify { @query_interface.query(@query).should be_near(@result) }
      end
      describe "ignores duplicates" do
        before { @query = "SUM(VALUE(ca,ca,cb,cb,cd;demand))"; @result = 6.0 }
        specify { @query_interface.check(@query).should be_true }
        specify { @query_interface.query(@query).should be_near(@result) }
      end
      describe "with group" do
        before { @query = "SUM(VALUE(GROUP(foo);demand))"; @result = 3.0 }
        specify { @query_interface.check(@query).should be_true }
        specify { @query_interface.query(@query).should be_near(@result) }
      end
    end

    describe "IF" do
      query_should_be_close "IF(LESS(1,3),50,100)", 50.0, 'is true'
      query_should_be_close "IF(LESS(3,1),50,100)", 100.0, 'is false'
      query_should_be_close "IF(LESS(1,3),IF(LESS(3,1),50,10),100)", 10.0, 'nested IFs'

      describe "invalid queries" do
        describe "condition is not a boolean" do
          before { @query = "IF(5,50,100)" }
          specify do
            lambda {
              @query_interface.query(@query)
            }.should raise_exception
          end
        end
        describe "condition is not a boolean" do
          before { @query = "IF(LESS(1,5),50)" }
          specify do
            lambda {
              @query_interface.query(@query)
            }.should raise_exception
          end
        end
      end
    end

    describe "IS_NUMBER" do
      query_should_eql "IS_NUMBER(1)", true
      query_should_eql "IS_NUMBER(BILLIONS)", true
      query_should_eql "IS_NUMBER(LESS(1,3))", false
      query_should_eql "IS_NUMBER(NIL())", false
    end

    describe "IS_NIL" do
      query_should_eql "IS_NIL(NIL())", true
      query_should_eql "IS_NIL(1)", false
    end

    describe "RESCUE" do
      query_should_be_close "RESCUE(AVG(NIL());5)", 5.0
      query_should_be_close "RESCUE(AVG(NIL()))", 0.0, "withouth param rescues with default 0.0"
    end

    describe "FOR_COUNTRIES" do
      describe "for de" do
        before { Current.scenario.country = 'de' }
        query_should_be_close "FOR_COUNTRIES(5;nl;en;de)", 5.0
      end
      describe "for nl" do
        before { Current.scenario.country = 'nl' }
        query_should_be_close "FOR_COUNTRIES(5;nl;en;de)", 5.0
      end
      describe "for country not in the list" do
        before { Current.scenario.country = 'ch' }
        query_should_eql "FOR_COUNTRIES(5;nl;en;de)", nil
      end
    end
  end

end

end
