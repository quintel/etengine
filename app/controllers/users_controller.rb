class UsersController < ApplicationController
  authorize_resource class: false
  before_action :find_user, only: %i[edit update destroy]

  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def edit; end

  def update
    @user.attributes = user_attributes

    if @user.save
      @user.staff_applications.destroy_all unless @user.admin?
      redirect_to users_path, notice: 'User updated'
    else
      render :edit
    end
  end

  def create
    @user = User.new(user_attributes)

    @user.role_id = params[:user][:role_id] if current_user && current_user.admin?

    if @user.save
      redirect_to users_path, notice: 'User added'
    else
      render :new
    end
  end

  def resend_confirmation_email
    user = User.find_by(id: params[:id])

    if user.nil?
      flash[:notice] = 'User does not exist.'
    elsif user.confirmed_at?
      flash[:notice] = 'User is already confirmed.'
    else
      user.send_confirmation_instructions
      flash[:notice] = "Confirmation email resent to #{user.email}."
    end
    redirect_to users_path
  end

  private

  def find_user
    @user = User.find(params[:id])
  end

  def user_attributes
    params.require(:user).permit(:email, :name, :admin)
  end
end
