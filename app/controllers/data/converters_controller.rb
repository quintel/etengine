class Data::ConvertersController < Data::BaseController
  before_filter :calculate_gql

  def index
    base = @blueprint.converter_records
    base = base.in_group(params[:group_id]) unless params[:group_id].blank?
    @converters = base.by_name(params[:q]).page(params[:page]).per(100)
  end

  def edit
    redirect_to edit_data_converter_converter_data_url(:converter_id => params[:id])
  end

  def show
    @qernel_graph = @graph.gql.present_graph
    @converter = Converter.find(params[:id])
    @converter_present = @graph.gql.present_graph.graph.converter(params[:id].to_i)
    @converter_future  = @graph.gql.future_graph.graph.converter(params[:id].to_i)

    respond_to do |format|
      format.html { render :layout => true }
      format.png  { render :text => diagram.to_png }
      format.svg  { render :text => diagram.to_svg }
    end
  end

  protected

    # calculate so values will be updated and assigned.
    def calculate_gql
      Current.gql.prepare
    end

    def diagram
      depth = params[:depth].andand.to_i || 3
      base_url = "/data/latest/nl/converters/"
      converter = params[:graph] == 'future' ? @converter_future : @converter_present
      converter.to_image(depth, base_url)
    end
end
