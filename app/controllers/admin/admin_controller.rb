class Admin::AdminController < ApplicationController
  layout 'admin'
  
  before_filter :restrict_to_admin
end
  