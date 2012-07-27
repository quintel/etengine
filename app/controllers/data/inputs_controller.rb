class Data::InputsController < Data::BaseController
  layout 'application'

  before_filter :find_input, :only => [:show]

  def index
    @inputs = Input.all.sort_by(&:key)
  end

  def show
  end

  private

    def find_input
      @input = Input.get(params[:id])
    end
end
