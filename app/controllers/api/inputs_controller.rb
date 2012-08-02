class Api::InputsController < Api::BaseController
  respond_to :xml

  def index
    respond_with(@inputs = Input.all)
  end
end