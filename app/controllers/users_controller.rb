class UsersController < ApplicationController
  authorize_resource :class => false
  before_filter :find_user, :only => [:show, :edit, :update, :destroy]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def update
    if @user.update_attributes(params[:user])
      if current_user.try(:admin?)
        @user.role_id = params[:user][:role_id] and @user.save
      end
      redirect_to @user, :notice => 'User updated'
    else
      render :edit
    end
  end

  def create
    @user = User.new(params[:user])
    @user.role_id = params[:user][:role_id] if current_user.try(:admin?)
    if @user.save
      redirect_to @user, :notice => 'User added'
    else
      render :new
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, :notice => 'User deleted'
  end

  private

    def find_user
      @user = User.find(params[:id])
    end
end
