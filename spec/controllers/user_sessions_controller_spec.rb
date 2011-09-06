require 'spec_helper'

describe UserSessionsController do
  render_views
  
  before(:each) do
    stub_etm_layout_methods!    
    @user = Factory(:user)
    @password = "password"
  end
  
  context "User is not logged in" do
    it "should get to the login page" do
      get :new
      response.should be_success
      response.should have_selector("form") do |form|
        form.should have_selector("input", :type => "email", :name => "user_session[email]")
        form.should have_selector("input", :type => "password", :name => "user_session[password]")
      end
    end
    
    it "should redirect to admin after succesfull loggin in" do
      post :create, :user_session => {:email => @user.email, :password => @user.password}
      assigns(:user_session).user.should == @user
      response.should redirect_to('/data/latest/nl')
    end

    it "should render the same page t to admin after unsuccessfull login." do
      post :create, :user_session => {:email => @user.email, :password => 'pssassword'} 
      controller.send(:current_user).should be_nil
      response.should be_success
    end
  end  
end
