class Data::GqueriesController < Data::BaseController
  cache_sweeper Sweepers::Gquery
  sortable_attributes :key, :updated_at,:gquery_group => "`gquery_group`"

  def index
    if params[:key] && q = Gquery.find_by_key(params[:key])
      redirect_to data_gquery_path(:id => q.id) and return
    end
    
    sort = params[:sort] ? "`#{params[:sort]}`" : "`key`"
    order = params[:order] == 'ascending' ? "asc" : "desc" 

    unless params[:groups].blank?
      @gqueries = GqueryGroup.where("`id` IN (#{params[:groups]})").map(&:gqueries) 
    else
      params[:groups] = ''
      @gqueries = Gquery.find(:all, :order =>"#{sort} #{order}")
    end
    respond_to do |format|
      format.html { render }
    end
  end

  def dump
    sort = params[:sort] ? "`#{params[:sort]}`" : "`gquery_group_id`"
    order = params[:order] == 'ascending' ? "asc" : "desc" 
    
    @gqueries = Gquery.order("#{sort} #{order}")    
    @gqueries = @gqueries.contains(params[:search]) if params[:search]
  end

  def test
    @query = params[:query].gsub(/\s/,'') if params[:query].present?
  end

  def show
    find_model
  end

  def edit
    find_model
  end

  def result
    raw_query = params[:id] ? Gquery.find(params[:id]) : (params[:query] ? params[:query] : '')
    @query = Gql::QueryInterface::Preparser.new(raw_query).clean
    render 'result'
  end

  def new
    @gquery = Gquery.new
  end

  def update
    @gquery = Gquery.find(params[:id])
    if @gquery.update_attributes(params[:gquery])
      assign_query_groups(@gquery, params[:gquery_groups])
      flash[:notice] = "Gquery updated"
      redirect_to data_gquery_url(:id => @gquery)
    else
      flash[:error] = "Save failed!"
      render :action => 'edit'
    end
  end

  def create
    @gquery = Gquery.new(params[:gquery])
    if @gquery.save
      assign_query_groups(@gquery, params[:gquery_groups])
      flash[:notice] = "Gquery created"
      redirect_to data_gquery_url(:id => @gquery)
    else
      render :action => 'new'
    end
  end

  def destroy
    @gquery = Gquery.find(params[:id])
    if @gquery.destroy
      flash[:notice] = "Gquery #{@gquery.name} deleted"
    else
      flash[:error] = "Gquery #{@gquery.name} not deleted"
    end
    redirect_to data_gqueries_url
  end
  
  private

    def find_model
      if params[:version_id]
        @version = Version.find(params[:version_id])
        @gquery = @version.reify
        flash[:notice] = "Revision"
      else
        @gquery = Gquery.find(params[:id])
      end
    end
  
    def assign_query_groups(gquery,groups)
      return unless groups.kind_of?(Array)
      groups.each do |group|
        gquery.gquery_groups.delete_all
        GqueriesGqueryGroup.new(:gquery_group_id => group, :gquery_id => gquery.id).save
      end
    end
end
