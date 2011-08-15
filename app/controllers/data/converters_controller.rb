class Data::ConvertersController < Data::BaseController

  def index
  end

  def edit
    redirect_to edit_data_converter_converter_data_url(:converter_id => params[:id])
  end

  def show
    @qernel_graph = @graph.gql.present
    @converter = Converter.find(params[:id]) # was is ment to be params{id}? it failed..
    @converter_present = @graph.gql.present.converter(params[:id].to_i)
    @converter_future  = @graph.gql.future.converter(params[:id].to_i)

    respond_to do |format|
      format.html { render :layout => true }
      format.png  { render :text => diagram.to_png }
      format.svg  { render :text => diagram.to_svg }
    end
  end

private
  def diagram
    depth = params[:depth].andand.to_i || 3
    base_url = "/data/latest/nl/converters/"
    converter = params[:graph] == 'future' ? @converter_future : @converter_present
    converter.to_image(depth)
  end

end
