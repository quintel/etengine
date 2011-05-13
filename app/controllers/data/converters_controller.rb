class Data::ConvertersController < Data::DataController

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
  end

end
