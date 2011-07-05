class Data::CarriersController < Data::BaseController
  def index
    
  end

  def edit
    @carrier = Carrier.find(params[:id])
    @carrier_data = @dataset.carrier_area_datas.where(:carrier_id => params[:id]).first
  end

  def show
    redirect_to edit_data_carrier_carrier_data_url(:carrier_id => params[:id])
  end

end
