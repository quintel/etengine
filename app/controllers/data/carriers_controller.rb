class Data::CarriersController < Data::BaseController
  def index
    @carriers = @gql.present_graph.carriers
  end

  def show
    @carrier = @gql.present_graph.carrier(params[:id].to_sym)
  end
end
