class Data::ConvertersController < Data::BaseController
  layout 'application'

  def index
    all = @gql.present_graph.converters
    all.select!{|c| c.key.to_s.include?(params[:q])} if params[:q]
    all.select!{|c| c.groups.include?(params[:group].to_sym) } if params[:group].present?

    @converters = Kaminari.paginate_array(all.sort_by(&:key)).
      page(params[:page]).per(50)
  end

  def show
    key = params[:id].to_sym
    @qernel_graph = @gql.present_graph
    @converter_present = @gql.present_graph.graph.converter(key.to_sym)
    @converter_future  = @gql.future_graph.graph.converter(key.to_sym)
    @converter_api  = @converter_present.converter_api
    @presenter = Api::V3::ConverterPresenter.new(key, @api_scenario)

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
