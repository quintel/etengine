module Admin
  class BlueprintModelsController < BaseController
    def index
      @blueprint_models = BlueprintModel.all
    end

  #protected
  #
  #  def find_graph
  #    blueprint_id = params[:blueprint_id]
  #    region_code  = params[:region_code]
  #
  #    if region_code and blueprint_id
  #      @graph = Graph.latest_from_country(region_code)
  #
  #      # We have to assign the gql to Current. So that we are able
  #      #  to use Current.gql.query().
  #      Current.gql = @graph.gql
  #      @present_graph = @graph.gql.present_graph
  #      @future_graph  = @graph.gql.future_graph
  #
  #      @blueprint  = @graph.blueprint
  #      @dataset = @graph.dataset
  #    end
  #  end
  #
  end
end