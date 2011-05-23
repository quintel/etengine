class Api::ScenariosController < ApplicationController
  respond_to :xml
  
  before_filter :find_scenario, :only => [:show, :load]

  def index
    respond_with(@scenarios = Scenario.where(:in_start_menu => true))
  end

  def show
    respond_with(@scenario)
  end
  
  def load
    respond_with(@scenario.load!)
  end
  
  # def users_scenarios
  #   current_user.stored_scenarios
  #   RemoteUserScenario {:user_id, :api_session_id, :name, :settings}
  #   
  # end
  # 
  # def load
  #   globals.api_session_id = api_session_id
  # end
  
  private
    
    def find_scenario
      @scenario = Scenario.find params[:id]
    end
end