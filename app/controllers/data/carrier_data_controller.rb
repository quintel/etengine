class Data::CarrierDataController < Data::DataController
  before_filter :find_model

  def find_model
    if params[:version_id]
      @version = Version.find(params[:version_id])
      @carrier_data = @version.reify
      @carrier = @carrier_data.carrier
      flash[:notice] = "Revision"
    elsif params[:carrier_id]
      @carrier = Carrier.find(params[:carrier_id])
      @carrier_data = @dataset.carrier_area_datas.where(:carrier_id => params[:carrier_id]).first
    else
      @carrier_data = CarrierData.find(params[:id])
      @carrier = @carrier_data.carrier
    end
  end

  def update
    if @carrier_data.update_attributes(params[:carrier_data])
      flash[:notice] = "Carrier has been updated."
      redirect_to edit_data_carrier_carrier_data_url(:carrier_id => @carrier.id)
    else
      render :action => 'edit'
    end
  end

  def edit
  end

end
