module MechanicalTurk
  class BaseController < ApplicationController
    authorize_resource :class => false
  end
end
