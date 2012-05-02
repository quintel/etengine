class Data::GqueriesController < Data::BaseController
  before_filter :find_model, :only => [:show, :edit]

  def index
    @gqueries = Kaminari.paginate_array(Gquery.all.sort_by(&:key)).page(params[:page]).per(50)
  end

  def dump
    sort = params[:sort] ? "`#{params[:sort]}`" : "`gquery_group_id`"
    order = params[:order] == 'ascending' ? "asc" : "desc"

    @gqueries = Gquery.all
    @gqueries = @gqueries.contains(params[:search]) if params[:search]
  end

  def test
    @query = params[:query].gsub(/\s/,'') if params[:query].present?
  end

  def show
  end

  def edit
  end

  def result
    raw_query = params[:id] ? Gquery.find(params[:id]).query : (params[:query] ? params[:query] : '')
    @query = Gquery.convert_to_rubel!(raw_query)
    render 'result'
  end

  # Similar to the show action, but finding the gquery by key. It makes sense to
  # keep the two actions separated.
  # SB (2011-12-06): Why does it make sense to keep the two actions separated?
  def key
    @gquery = Gquery.get(params[:key]) rescue nil
    if @gquery
      render :show
    else
      redirect_to data_gqueries_path(:q => params[:key]), :alert => 'Gquery key not found!'
    end
  end

  private

    def find_model
      @gquery = Gquery.get(params[:id])
    end

    def assign_query_groups(gquery,groups)
      return unless groups.kind_of?(Array)
      groups.each do |group|
        gquery.gquery_groups.delete_all
        GqueriesGqueryGroup.new(:gquery_group_id => group, :gquery_id => gquery.id).save
      end
    end
end
