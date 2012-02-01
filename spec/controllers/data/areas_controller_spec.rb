require 'spec_helper'

describe Data::AreasController do
  let(:admin)     { Factory :admin }
  let!(:area)     { Factory :area, :country => 'nl' }

  before do
    login_as(admin)
  end

  describe "GET show" do
    it "should be successful" do
      get :show, :api_scenario_id => 'latest'
      response.should render_template(:show)
    end
  end
end
