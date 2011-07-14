require 'spec_helper'

describe ApiScenario do

  describe "#new" do
    it "should copy the id to api_session_key if empty" do
      api_scenario = ApiScenario.create!(ApiScenario.new_attributes)
      api_scenario.api_session_key.should == api_scenario.id
    end

    # Feature not supported atm (2011-07-14)
    # it "should not copy the id to api_session_key if already defined" do
    #   api_scenario = ApiScenario.create!(ApiScenario.new_attributes(:id => 'foo'))
    #   api_scenario.api_session_key.should_not == api_scenario.id
    # end
  end
end




