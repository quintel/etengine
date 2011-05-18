require 'spec_helper'

describe Admin::PagesController do
  render_views
  
  let(:admin) { Factory :admin }
  before do
    login_as(admin)
  end
  
  describe "on GET index" do
    before { get :index }
    
    it { should render_template(:index) }
  end
end
