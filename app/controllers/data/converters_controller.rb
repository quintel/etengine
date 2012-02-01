class Data::ConvertersController < Data::BaseController
  def index
    @converters = @gql.present_graph.converters
    if params[:q]
      @converters = @converters.select{|c| c.full_key.to_s.include?(params[:q])}
    end
    unless params[:group_id].blank?
      group = Group.find(params[:group_id])
      @converters = @converters.select{|c| c.groups.include?(group.key.to_sym) }
    end
    page, per_page = params[:page] || 1, 100
    @num_pages = @converters.length / per_page
    @converters = @converters.sort_by(&:full_key)[((page - 1) * per_page)...(page * per_page)]

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
