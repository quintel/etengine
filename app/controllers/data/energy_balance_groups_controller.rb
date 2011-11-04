class Data::EnergyBalanceGroupsController < Data::BaseController
  before_filter :find_item, :only => [:show, :edit, :update, :destroy]
  
  def index
    @energy_balance_groups = EnergyBalanceGroup.all
  end
  
  def show
  end
  
  def edit
  end
  
  def new
    @energy_balance_group = EnergyBalanceGroup.new
  end
  
  def create
    @energy_balance_group = EnergyBalanceGroup.new(params[:energy_balance_group])
    if @energy_balance_group.save
      flash[:notice] = "Energy Balance Group added"
      redirect_to data_energy_balance_group_path(:id => @energy_balance_group.id)
    else
      render :new
    end
  end
  
  def update
    if @energy_balance_group.update_attributes(params[:energy_balance_group])
      flash[:notice] = "Energy Balance Group updated"
      redirect_to data_energy_balance_group_path(:id => @energy_balance_group.id)
    else
      render :edit
    end
  end
  
  def destroy
    @energy_balance_group.destroy
    flash[:notice] = "Energy Balance Group deleted"
    redirect_to data_energy_balance_groups_path
  end
  
  private
    
    def find_item
      @energy_balance_group = EnergyBalanceGroup.find params[:id]
    end
end