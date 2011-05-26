module EtmHelper  
  # Stubs methods that are needed to just render the etm layout
  def stub_etm_layout_methods!
    Current.stub!(:graph)
  end
end