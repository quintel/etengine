class Data::DescriptionsController < Data::DataController


  def index
    
  end

  def edit
    find_model
  end

  def update
    @description = Description.find(params[:id])
    if @description.update_attributes(params[:description])
      flash[:notice] = "Successfully updated description."
      redirect_to edit_data_description_path(@description)
    else
      render :action => 'edit'
    end
  end

  def new
    @description = Description.new(:describable_id => params[:describable_id], :describable_type => params[:describable_type])
  end

  def create
    @description = Description.new(params[:description])
    if @description.save
      flash[:notice] = "Successfully created description."
      redirect_to edit_data_description_path(@description)
    else
      redirect_to :back
    end
  end

  def show
    find_model
  end

  def find_model
    if params[:version_id]
      @version = Version.find(params[:version_id])
      @description = @version.reify
      flash[:notice] = "Revision"
    else
      @description = Description.find(params[:id])
    end
  end
end
