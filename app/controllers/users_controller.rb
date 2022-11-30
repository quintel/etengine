class UsersController < ApplicationController
  authorize_resource :class => false
  before_action :find_user, :only => [:edit, :update, :destroy]

  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def edit
  end

  def update
    @user.attributes = user_attributes

    if current_user && current_user.admin?
      @user.role_id = params[:user][:role_id]
    end

    if @user.save
      redirect_to users_path, notice: 'User updated'
    else
      render :edit
    end
  end

  def create
    @user = User.new(user_attributes)

    if current_user && current_user.admin?
      @user.role_id = params[:user][:role_id]
    end

    if @user.save
      redirect_to users_path, :notice => 'User added'
    else
      render :new
    end
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

  def user_attributes
    params.require(:user).permit(:email, :name, :password, :admin)
  end
end
