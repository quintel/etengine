# This controller is mostly used for ActiveResource requests. Check ApiScenariosController
# to see how the API requests work.
#
class Api::ScenariosController < Api::BaseController
  respond_to :xml

  before_filter :find_scenario, :only => [:show, :load, :update]

  def index
    @scenarios = Scenario.recent_first.page(params[:page]).per(20)
    respond_with(@scenarios)
  end

  # ETM uses this to fill the preset scenarios select box
  #
  def homepage
    @scenarios = Preset.all.map(&:to_scenario).select(&:in_start_menu).sort_by(&:id)
    respond_with @scenarios
  end

  def show
    if @scenario
      respond_with(@scenario)
    else
      render :text => 'record missing', :status => 404
    end
  end

  def create
    api_session_id = params[:scenario].delete("api_session_id")

    if api_session_id
      api_scenario = Scenario.find(api_session_id)
      # this creates a copy of the scenario
      @scenario = api_scenario.save_as_scenario(params[:scenario])
    else
      @scenario = Scenario.create(params[:scenario])
    end
    respond_with(@scenario)
  end

  # Is this still used?
  # PZ - Thu 17 Nov 2011 15:22:02 CET
  def update
    @scenario.update_attributes(params[:scenario])
    respond_with(@scenario)
  end

  # Is this still used?
  # PZ - Thu 17 Nov 2011 15:22:02 CET
  def load
    respond_with(@scenario)
  end

  private

    def find_scenario
      @scenario = Preset.get(params[:id]).try(:to_scenario) || Scenario.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn "*** ActiveResource 404 Error"
      nil
    end
end
