class Api::ScenariosController < ApplicationController
  respond_to :xml
  
  before_filter :find_scenario, :only => [:show, :load, :update]

  def index
    respond_with(@scenarios = Scenario.exclude_api.recent_first)
  end
  
  def homepage
    respond_with(@scenarios = Scenario.where(:in_start_menu => true))
  end

  def show
    respond_with(@scenario)
  end
  
  def create
    @scenario = Scenario.new(params[:scenario])
    @scenario.save
    respond_with(@scenario)
  end
  
  def update
    @scenario.update_attributes(params[:scenario])
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
      # DEBT
      @scenario = Scenario.find_by_api_session_key(params[:id]) || Scenario.find(params[:id])
    end
end