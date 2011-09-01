class Data::FceValuesController < Data::BaseController
  sortable_attributes :carrier, :origin_country, :using_country

  def index
    sort = params[:sort] ? "`#{params[:sort]}`" : "`carrier`"
    order = params[:order] == 'ascending' ? "asc" : "desc" 

    @fce_values = FceValue.find(:all, :order =>"#{sort} #{order}")
    respond_to do |format|
      format.html { render }
    end
  end

  def show
    find_model
  end

  def edit
    find_model
  end

  def new
    @fce_value = FceValue.new
  end

  def update
    @fce_value = FceValue.find(params[:id])
    if @fce_value.update_attributes(params[:fce_value])
      flash[:notice] = "fce_value updated"
      redirect_to data_fce_value_url(:id => @fce_value)
    else
      flash[:error] = "Save failed!"
      render :action => 'edit'
    end
  end

  def create
    @fce_value = FceValue.new(params[:fce_value])
    if @fce_value.save
      flash[:notice] = "FceValue created"
      redirect_to data_fce_value_url(:id => @fce_value)
    else
      render :action => 'new'
    end
  end

  def destroy
    @fce_value = FceValue.find(params[:id])
    if @fce_value.destroy
      flash[:notice] = "Fce value deleted"
      redirect_to data_fce_values_url
    else
      flash[:error] = "Fce value not deleted"
      redirect_to data_fce_values_url
    end
  end
  
  private

    def find_model
      if params[:version_id]
        @version = Version.find(params[:version_id])
        @fce_value = @version.reify
        flash[:notice] = "Revision"
      else
        @fce_value = FceValue.find(params[:id])
      end
    end
end
