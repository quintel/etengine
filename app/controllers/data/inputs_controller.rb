class Data::InputsController < Data::BaseController
  before_filter :find_input, :only => [:edit, :update, :destroy]
  cache_sweeper Sweepers::Input
  
  def index
    @inputs = Input.by_name(params[:q]).sort_by(&:key)
  end

  def edit
  end

  private
  
    def find_input
      @input = Input.find params[:id]
    end
end
