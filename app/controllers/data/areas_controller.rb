class Data::AreasController < Data::BaseController
  before_filter :find_model, :only => [:update, :show, :edit]

  def index
    @areas = Area.by_name(params[:q])
  end

  def new
    @area = Area.new
  end

  def create
    @area = Area.new(params[:area])
    if @area.save
      flash[:notice] = "Successfully created area and carrier datas."
      redirect_to data_area_path(:id => @area.id)
    else
      render :action => 'new'
    end
  end

  def update
    if @area.update_attributes(params[:area])
      flash[:notice] = "Successfully updated area."
      redirect_to data_area_path(:id => @area.id)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @area = Area.find(params[:id])
    @area.destroy
    flash[:notice] = "Successfully destroyed area."
    redirect_to data_areas_url
  end

  def show
  end

  def edit
  end

  private

    def find_model
      if params[:version_id]
        @version = Version.find(params[:version_id])
        @area = @version.reify
        flash[:notice] = "Revision"
      else
        if params[:id]
          @area = Area.find(params[:id])
        else
          @area = Area.find_by_country(params[:region_code])
        end
      end
    end
end
