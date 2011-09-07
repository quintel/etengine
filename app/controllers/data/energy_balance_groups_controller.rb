class Data::EnergyBalanceGroupsController < Data::BaseController
  def index
    @energy_balance_groups = EnergyBalanceGroup.all
  end
  
  def show
    @energy_balance_group = EnergyBalanceGroup.find params[:id]
  end
end