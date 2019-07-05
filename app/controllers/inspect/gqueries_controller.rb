class Inspect::GqueriesController < Inspect::BaseController
  layout 'application'

  before_action :find_model, :only => :show
  skip_before_action :initialize_gql, :only => [:index]

  def index
    all = Gquery.all
    all = all.select{|g| g.key.include?(params[:q])} unless params[:q].blank?
    all = all.select{|g| g.group_key == params[:group].to_sym} unless params[:group].blank?
    @gqueries = Kaminari.paginate_array(all.sort_by(&:key)).page(params[:page]).per(50)
  end

  # GET test
  def test
    if params[:commit] == "Debug"
      redirect_to inspect_debug_gql_path(gquery: params[:query])
    elsif params[:query].present?
      begin
        @result = @gql.query(params[:query].gsub(/\s/,''), nil, true)
      rescue Gql::CommandError => ex
        @error = ex
      end
    end
  end

  def show
    @result = @gql.query(@gquery)
  end

  def result
    if params[:id]
      @query = Gquery.find(params[:id]).command
    else
      @query = Gql::Command.new(params[:query] ? params[:query] : '')
    end
  end

  #######
  private
  #######

  def find_model
    @gquery = Gquery.get(params[:id]) || render_not_found('gquery')
  end

end
