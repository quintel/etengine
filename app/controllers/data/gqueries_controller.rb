class Data::GqueriesController < Data::BaseController
  layout 'application'

  before_filter :find_model, :only => :show
  skip_before_filter :initialize_gql, :only => [:index]

  def index
    all = Gquery.all
    all = all.select{|g| g.key.include?(params[:q])} unless params[:q].blank?
    all = all.select{|g| g.group_key == params[:group].to_sym} unless params[:group].blank?
    @gqueries = Kaminari.paginate_array(all.sort_by(&:key)).page(params[:page]).per(50)
  end

  def test
    if params[:commit] == "Debug"
      redirect_to data_debug_gql_path(gquery: params[:query])
    else
      @query = params[:query] if params[:query].present?
    end
  end

  def show
  end

  def result
    raw_query = params[:id] ? Gquery.find(params[:id]).query : (params[:query] ? params[:query] : '')
    @query = Gquery.convert_to_rubel!(raw_query)
    render 'result'
  end

  #######
  private
  #######

  def find_model
    @gquery = Gquery.get(params[:id])
  end

end
