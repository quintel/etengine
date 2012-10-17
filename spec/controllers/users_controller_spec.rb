require 'spec_helper'

describe UsersController do
  let(:admin) {FactoryGirl.create :admin}

  describe "GET index" do
    it "should redirect non admins" do
      get :index
      response.should be_redirect
    end

    it "should work for admins" do
      login_as admin
      get :index
      response.should be_success
      response.should render_template(:index)
    end
  end

  describe "GET edit" do
    it "should redirect guests" do
      get :edit, :id => admin.id
      expect(response).to be_redirect
    end

    it "should work for admins" do
      login_as admin
      get :edit, :id => admin.id
      expect(response).to be_success
      expect(assigns(:user)).to eq(admin)
      expect(response).to render_template(:edit)
    end
  end
end
