require 'spec_helper'

describe Data::DataController do
  let(:admin) { Factory :admin }
  
  before do
    login_as(admin)
  end
  
  describe "GET start" do
    it "should redirect the user to a better page" do
      get :start
      response.should redirect_to(data_converters_url(:blueprint_id =>'latest', :region_code => 'nl'))
    end
  end
end
