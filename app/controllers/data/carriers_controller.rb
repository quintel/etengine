class Data::CarriersController < Data::BaseController
  def index
    @carriers = Carrier.all
  end

  def edit
    @carrier = Carrier.find(params[:id])
    @carrier_data = @dataset.carrier_area_datas.where(:carrier_id => params[:id]).first
  end
end
