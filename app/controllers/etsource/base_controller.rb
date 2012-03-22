class Etsource::BaseController < ApplicationController
  layout 'etsource'
  
  authorize_resource :class => false

end
