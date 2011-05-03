class Data::DataController < ApplicationController
  layout 'data'
  before_filter :restrict_to_admin

  before_filter :find_graph

  def start
    redirect_to data_converters_url(
      :blueprint_id => params[:blueprint_id] || 'latest', 
      :region_code => params[:region_code] || 'nl')
  end

  def redirect
    redirect_to data_converters_url(
      :blueprint_id => params[:blueprint_id] || 'latest', 
      :region_code => params[:region_code] || 'nl')
  end


protected

  def find_graph
    blueprint_id = params[:blueprint_id]
    region_code  = params[:region_code]

    if region_code and blueprint_id
      @graph = Graph.latest_from_country(region_code)

      # We have to assign the gql to Current. So that we are able
      #  to use Current.gql.query().
      Current.gql = @graph.gql
      @present_graph = @graph.gql.present
      @future_graph  = @graph.gql.future

      @blueprint  = @graph.blueprint
      @dataset = @graph.dataset
    end
  end

end
