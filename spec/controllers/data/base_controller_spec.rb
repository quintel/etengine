require 'spec_helper'

describe Data::BaseController do
  let!(:admin) { FactoryGirl.create :admin }
  let!(:graph) { FactoryGirl.create :graph }

  before do
    login_as(admin)
  end
  
  describe "GET start" do
    it "should redirect the user to a better page" do
      get :start, :blueprint_id =>'latest', :region_code => 'nl'
      response.should redirect_to(data_converters_url(:blueprint_id =>'latest', :region_code => 'nl'))
    end
  end
end
