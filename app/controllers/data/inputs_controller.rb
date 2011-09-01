class Data::InputsController < Data::BaseController

  def index
    @columns = Input.column_names
    @inputs = Input.all
  end

  def show
    @input = Input.find(params[:id])
  end

  def edit
    @input = Input.find(params[:id])
  end

  def new
    @input = Input.new
  end

  def create
    @input = Input.new(params[:input])
    if @input.save
      redirect_to admin_inputs_path
    else
      render :action => 'new'
    end
  end

  def update
    @input = Input.find(params[:id])
    if @input.update_attributes(params[:input])
      flash[:notice] = "Input updated"
      redirect_to admin_inputs_path
    else
      render :action => 'edit'
    end
  end

  def destroy
    @input = Input.find(params[:input])
    if @input.destroy
      flash[:notice] = "Input destroyed!"
      redirect_to admin_inputs_path
    else
      flash[:error] = "Error while deleting slider."
      render :action => 'edit'
    end
  end

end
