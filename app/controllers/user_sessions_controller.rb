class UserSessionsController < ApplicationController
  layout 'pages'
  
  before_filter :require_no_user, :only => :new

  def index
    @user_session = UserSession.new
    render :action=>"new"
  end

  def new
    @user_session = UserSession.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @user_session }
    end
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|
       if result
        flash[:notice] = I18n.t("flash.login")
        
        if params[:redirect_to]
          redirect_to params[:redirect_to]
        elsif session[:return_to]
          redirect_to session[:return_to]
          clear_stored_location
        elsif UserSession.find.user.role.andand.name == "admin"
          redirect_to "/data"
        else
            redirect_to(root_url)
        end
      else
        respond_to do |format|
          format.html { render :action => "new"}
          format.xml  { render :xml => @user_session }
        end
      end
    end
  end

  def destroy
    @user_session = UserSession.find
    @user_session.destroy if @user_session

    respond_to do |format|
      flash[:notice] = I18n.t("flash.logout")
      format.html { redirect_to(root_url) }
      format.xml  { head :ok }
    end
  end  
end
