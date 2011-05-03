class Construction::DatasetsController < Construction::ConstructionController


  def index
    @blueprints = Dataset.ordered
  end

  def new
    @blueprint = Blueprint.new
  end

  def create
    if params[:copy_blueprint_id]
      original = Blueprint.find(params[:copy_blueprint_id])
      blueprint = original.copy_blueprint!
      if blueprint.update_attributes(params[:blueprint])
        flash[:notice] = 'Blueprint Created'
        redirect_to construction_blueprints_url
      end
    else
      flash[:notice] = 'Specify a blueprint to copy from'
      render :action => 'new'
    end
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
#      @present_graph = @graph.gql.present
#      @future_graph  = @graph.gql.future
#
#      @blueprint  = @graph.blueprint
#      @dataset = @graph.dataset
#    end
#  end
#
end
