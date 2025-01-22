class Etsource::BaseController < ApplicationController
  layout 'application'

  authorize_resource :class => false

end
