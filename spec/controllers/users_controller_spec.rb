require 'spec_helper'

describe UsersController do
  let(:admin) {FactoryBot.create :admin}

  describe "GET index" do
    it "should redirect non admins" do
      get :index
      expect(response).to be_redirect
    end

    it "should work for admins" do
      sign_in(admin)
      get :index
      expect(response).to be_success
      expect(response).to render_template(:index)
    end
  end

  describe "GET edit" do
    it "should redirect guests" do
      get :edit, params: { :id => admin.id }
      expect(response).to be_redirect
    end

    it "should work for admins" do
      sign_in(admin)
      get :edit, params: { :id => admin.id }
      expect(response).to be_success
      expect(assigns(:user)).to eq(admin)
      expect(response).to render_template(:edit)
    end
  end
end
