
class Data::AreasController < Data::BaseController
  def show
    @area = @gql.present_graph.area
  end
end
