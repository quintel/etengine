class Data::EnergyBalanceGroupsController < Data::BaseController
  layout 'application'

  before_filter :find_item, :only => [:show, :edit, :update, :destroy]
  
  def index
    @energy_balance_groups = EnergyBalanceGroup.order('name').all
  end
  
  def show
    @energy_balance_group = EnergyBalanceGroup.find params[:id]
  end
end