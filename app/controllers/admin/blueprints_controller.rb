module Admin
  class BlueprintsController < BaseController
    def index
      @blueprints = Blueprint.ordered.includes(:datasets)
    end

    def new
      @blueprint = Blueprint.new()
      @copy_blueprint = Blueprint.find(params[:copy_blueprint_id]) if params[:copy_blueprint_id]
    end

    def show
      @blueprint = Blueprint.find(params[:id])
    end

    def create
      if params[:copy_blueprint_id]
        original = Blueprint.find(params[:copy_blueprint_id])
        blueprint = original.copy_blueprint!
        blueprint.update_attributes(params[:blueprint])

        notice = 'Blueprint Created'

        params[:copy_dataset_id].each do |copy_dataset_id|
          dataset = Dataset.find(copy_dataset_id)
          dataset.copy_dataset!(blueprint.id)
          notice += ", #{dataset.region_code}"
        end

        if blueprint.update_attributes(params[:blueprint])
          flash[:notice] = notice
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