class Data::ConverterDatasController < Data::BaseController
  before_filter :find_model

  def find_model
    if params[:converter_id]
      @converter = Converter.find(params[:converter_id])
      @converter_data = @dataset.converter_datas.where(:converter_id => params[:converter_id]).first
    else
      @converter_data = ConverterData.find(params[:id])
      @converter = @converter_data.converter
    end
  end

  def update
    if @converter_data.update_attributes(params[:converter_data])
      redirect_to data_converter_url(:id => @converter.id)
    else
      render :action => 'edit'
    end
  end

  def edit
  end
  
end
