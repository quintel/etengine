class PagesController < ApplicationController
  def index
    @user_session = UserSession.new unless current_user
  end
end