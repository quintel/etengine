class InputTool::BaseController < ApplicationController
  layout 'input'

  authorize_resource :class => false

  def redirect
    redirect_to input_root_path
  end

end
