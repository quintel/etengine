class Data::CarriersController < Data::BaseController
  layout 'application'

  def index
    @carriers = @gql.present_graph.carriers.sort_by(&:key)
  end

  def show
    @present_carrier = @gql.present_graph.carrier(params[:id].to_sym)
    @future_carrier  = @gql.future_graph.carrier(params[:id].to_sym)
  end
end
