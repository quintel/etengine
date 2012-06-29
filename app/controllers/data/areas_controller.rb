
class Data::AreasController < Data::BaseController
  def show
    @area_present = @gql.present_graph.area
    @area_future  = @gql.future_graph.area
  end
end
