require 'spec_helper'

describe Data::GqueriesController do
  render_views
  
  let(:admin) { Factory :admin }
  let!(:gquery) { Factory :gquery }
  
  before do
    login_as(admin)
  end
  
  describe "GET index" do
    it "should be successful" do
      get :index
      response.should render_template(:index)
    end
  end

  describe "GET new" do
    it "should be successful" do
      get :new
      response.should render_template(:new)
    end
  end

  describe "GET show" do
    it "should be successful" do
      get :show, :id => gquery.id
      response.should render_template(:show)
    end
  end

  describe "GET edit" do
    it "should be successful" do
      get :edit, :id => gquery.id
      response.should render_template(:edit)
    end
  end

end
