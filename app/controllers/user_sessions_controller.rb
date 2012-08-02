class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => :new

  def index
    @user_session = UserSession.new
    render :action=>"new"
  end

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Succesfully logged in to ETEngine."
      redirect_back_or_default data_root_path(:api_scenario_id => 'latest')
    else
      render :action => 'new'
    end
  end

  def destroy
    @user_session = UserSession.find
    @user_session.destroy if @user_session

    respond_to do |format|
      flash[:notice] = "Succesfully logged out of ETEngine."
      format.html { redirect_to(root_url) }
      format.xml  { head :ok }
    end
  end
end
