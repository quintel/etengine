class Api::AreasController < Api::BaseController
  respond_to :xml

  def show
    respond_with(@area = Area.get(params[:id]))
  end
end