class Data::InputsController < Data::BaseController
  before_filter :find_input, :only => [:edit, :update, :destroy]
  cache_sweeper Sweepers::Input
  
  def index
    @inputs = Input.all
  end

  def edit
  end

  def new
    @input = Input.new
  end

  def create
    @input = Input.new(params[:input])
    if @input.save
      redirect_to data_inputs_path
    else
      render :action => 'new'
    end
  end

  def update
    if @input.update_attributes(params[:input])
      flash[:notice] = "Input updated"
      redirect_to edit_data_input_path(:id => @input.id)
    else
      render :action => 'edit'
    end
  end

  def destroy
    if @input.destroy
      flash[:notice] = "Input destroyed!"
      redirect_to data_inputs_path
    else
      flash[:error] = "Error while deleting slider."
      render :action => 'edit'
    end
  end
  
  private
  
    def find_input
      @input = Input.find params[:id]
    end
end
