class Backend::AreasController < Backend::BaseController
  layout 'application'

  def show
    @area_present = @gql.present_graph.area
    @area_future  = @gql.future_graph.area
  end
end
