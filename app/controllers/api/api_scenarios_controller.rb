class Api::ApiScenariosController < ApplicationController
  layout 'api'

  before_filter :find_model, :only => [:update, :show, :destroy, :user_values]

  def index
    @api_scenarios = ApiScenario.order('updated_at DESC')

    respond_to do |format|
      format.html {  }
      format.json { render :json => @api_scenarios, :callback => params[:callback] }
    end
  end

  def new
    @api_scenario = ApiScenario.create!(new_attributes)
    respond_to do |format|
      format.html { redirect_to api_scenario_url(@api_scenario.api_session_key)}
      format.json { render :json => @api_scenario, :callback => params[:callback] }
    end
  end
  # create does the same like new, except that it is a POST request
  alias_method :create, :new

  ##
  # GET result[]=gquery_key&result[]=gquery_key2
  # 335=2.4&421=2.9
  def show
    Current.scenario = @api_scenario
    update_scenario(@api_scenario)
    @results = results
    @json = {
      'result'   => @results,
      'settings' => @api_scenario.serializable_hash(:only => [:api_session_key, :user_values, :country, :region, :start_year, :end_year, :lce_settings]),
      'errors'   => @api_scenario.api_errors(test_scenario?)
    }

    respond_to do |format|
      format.html { render }
      format.json { render :json => @json, :callback => params[:callback] }
    end
  end
  # update does the same like show, but it is a POST request
  alias_method :update, :show

  def destroy
    @api_scenario.destroy
    redirect_to api_scenarios_url
  end

  def user_values
    respond_to do |format|
      format.json do
        render :json => @api_scenario.user_values, :callback => params[:callback] 
      end
    end
  end

  ##
  # Is alias to show.
  #
  def find_model
    if test_scenario?
      @api_scenario = ApiScenario.new(new_attributes)
    else
      @api_scenario = ApiScenario.find_by_api_session_key(params[:id])
    end
  end

  private

    def test_scenario?
      params[:id] == 'test'
    end

    def new_attributes
      settings = params[:settings].present? ? params[:settings] : {}
      ApiScenario.new_attributes(settings)
    end

    def results
      if params[:result]
        @gqueries = params[:result].inject({}) do |hsh, key|
          if gquery = (Gquery.get(key) rescue nil)
            hsh.merge(gquery.key => Current.gql.query(gquery.query))
          else
            hsh.merge(key => Current.gql.query(key))
          end
        end
      else
        @gqueries = nil
      end
    end
  
    def update_scenario(scenario)
      scenario.reset! if params[:reset]
      if params[:input]
        scenario.update_input_elements_for_api(params[:input])
        # Save scenario with new user_values, except it is a test version
        scenario.save unless test_scenario?
      end
    end
end
