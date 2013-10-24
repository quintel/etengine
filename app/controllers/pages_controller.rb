class PagesController < ApplicationController
  def index
    if current_user
      @user_session = UserSession.new
    else
      redirect_to login_path
    end
  end
end
