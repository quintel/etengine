class Data::GroupsController < Data::BaseController
  def index
    @groups = Group.all
  end
  
  # Redirects to the main converter page. ATM the purpose of this action
  # is to create permalinks.
  def show
    @group = Group.find_by_key(params[:id])
    redirect_to data_converters_path(:group_id => @group.id)
  end
end
