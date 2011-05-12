module EtmHelper  
  # Stubs methods that are needed to just render the etm layout
  def stub_etm_layout_methods!
    ApplicationController.stub!(:ensure_valid_browser)
    Current.stub!(:graph)
  end
end