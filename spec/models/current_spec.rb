require 'spec_helper'

describe Current do

  describe "already_shown" do
    before {
      Current.session['already_shown'] = nil
    }
    context "not shown" do
      specify { Current.already_shown?('demand/intro').should be_false}
    end
    context "already shown" do
      before { Current.already_shown?('demand/intro') }
      specify { Current.already_shown?('demand/intro').should be_true}
    end
  end
  
  describe "gql_calculated?" do
    context "without gql" do
      before { Current.gql = nil }
      specify { Current.gql_calculated?.should be_false}
    end
    context "with uncalculated gql" do
      before { Current.gql = mock_model(Gql::Gql, :calculated? => false) }
      specify { Current.gql_calculated?.should be_false}
    end
    context "with calculated gql" do
      before { Current.gql = mock_model(Gql::Gql, :calculated? => true) }
      specify { Current.gql_calculated?.should be_true}
    end
  end  
end
