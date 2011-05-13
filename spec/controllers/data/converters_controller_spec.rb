require 'spec_helper'

describe Data::ConvertersController do
  let(:admin) { Factory :admin }
  
  before do
    login_as(admin)
  end
  
  describe "GET index" do
    it "should be successful" do
      get :index
      response.should render_template(:index)
    end
  end
end
