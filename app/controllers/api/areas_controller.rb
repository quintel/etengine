class Api::AreasController < Api::BaseController
  respond_to :xml

  def index
    respond_with(Etsource::Dataset.region_codes.map{|c| Area.get c})
  end

  def show
    respond_with(@area = Area.get(params[:id]))
  end
end