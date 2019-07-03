class Backend::InputsController < Backend::BaseController
  layout 'application'

  before_action :find_input, :only => [:show]

  def index
    @inputs = Input.all.sort_by(&:key)
  end

  def show
  end

  private

  def find_input
    @input = Input.get(params[:id]) || render_not_found('input')
  end
end
