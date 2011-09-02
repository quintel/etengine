class Data::BaseController < ApplicationController
  layout 'data'
  before_filter :restrict_to_admin
  before_filter :find_graph

  def kick
    Rails.cache.clear
    system("touch tmp/restart.txt")

    redirect_to data_converters_url(
      :blueprint_id => params[:blueprint_id],
      :region_code  => params[:region_code])
  end
  
  def redirect
    redirect_to data_root_path(
      :blueprint_id => params[:blueprint_id],
      :region_code  => params[:region_code])    
  end

  protected
    def find_graph
      blueprint_id = params[:blueprint_id] ||= 'latest'
      region_code  = params[:region_code] ||= 'nl'

      if blueprint_id != 'latest'
        @api_scenario = Scenario.find_by_api_session_key(blueprint_id)
        Current.scenario = @api_scenario
        @graph = Current.graph

      elsif region_code and blueprint_id
        @graph = Graph.latest_from_country(region_code)
        # We have to assign the gql to manually Current
        # DEBT: this is probablye not needed anymore. instead assign Current.graph = @graph
        Current.gql    = @graph.gql
      end
      @blueprint     = @graph.blueprint
      @dataset       = @graph.dataset
    end
end
