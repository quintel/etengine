class Data::ConvertersController < Data::BaseController
  def index
    base = @blueprint.converter_records
    base = base.in_group(params[:group_id]) unless params[:group_id].blank?
    @converters = base.by_name(params[:q]).order('converters.`key`').page(params[:page]).per(100)
  end

  def edit
    redirect_to edit_data_converter_converter_data_url(:converter_id => params[:id])
  end

  def show
    @qernel_graph = @gql.present_graph
    @converter_present = @gql.present_graph.graph.converter(params[:id].to_sym)
    @converter_future  = @gql.future_graph.graph.converter(params[:id].to_sym)

    respond_to do |format|
      format.html { render :layout => true }
      format.png  { render :text => diagram.to_png }
      format.svg  { render :text => diagram.to_svg }
    end
  end

  protected
  
    def diagram
      depth = params[:depth].andand.to_i || 3
      base_url = "/data/latest/nl/converters/"
      converter = params[:graph] == 'future' ? @converter_future : @converter_present
      converter.to_image(depth, base_url)
    end
end
