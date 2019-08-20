class Inspect::ConvertersController < Inspect::BaseController
  layout 'application'

  skip_authorize_resource :only => :show

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

    if @converter_present.nil?
      render_not_found('converter')
      return
    end

    @converter_api  = @converter_present.converter_api
    @presenter = Api::V3::ConverterPresenter.new(key, @api_scenario)

    respond_to do |format|
      format.html { render :layout => true }
      format.png  { render :plain => diagram.to_png }
      format.svg  { render :plain => diagram.to_svg }
    end
  end

  protected

    def diagram
      depth = params[:depth]&.to_i || 3
      base_url = "/inspect/#{@api_scenario.id}/converters/"
      converter = params[:graph] == 'future' ? @converter_future : @converter_present
      converter.to_image(depth, base_url)
    end
end