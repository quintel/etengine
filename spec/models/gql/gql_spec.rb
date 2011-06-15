require 'spec_helper'

module Gql

describe Gql do
  describe "initalize" do
    before {@gql = ::Gql::Gql.new(:testing)}
    specify {@gql.should_not be_nil}
  end
  describe "initalize" do
    before do
      @present = mock_model(::Qernel::Graph, :area => :area_present, 'year=' => nil)
      @future = mock_model(::Qernel::Graph, :area => :area_future, 'year=' => nil)
      @graph_model = mock_model(::Graph, 
        :present => @present,
        :future => @future
      )
      Current.stub!(:year).and_return(2010)
      Current.stub!(:end_year).and_return(2040)
      @gql = ::Gql::Gql.new(@graph_model)
    end
    subject { @gql}
    its(:present) { should == @present }
    its(:future) { should == @future }

    describe "#policy" do
      subject { @gql.policy }
      # TODO refactor This actually does not belong in here. should be tested in policy_spec
      its(:present_graph) { should == @present }
      its(:future_graph) { should == @future }
      its(:area) { should == :area_future }
      its(:present_area) { should == :area_present }
    end
  end

end

end
