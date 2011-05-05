module EtmHelper
  
  # Stubs methods that are needed to just render the etm layout
  def stub_etm_layout_methods!
    ApplicationController.stub!(:ensure_valid_browser)
    Current.stub!(:graph)
  end
  
  def logged_in_user
    controller.assigns["user_session"].andand.user
  end
    
  def log_in(user)
    controller.stub!(:current_user).and_return(user)
  end
  
end