class ApplicationController < ActionController::Base
  helper :all

  # TODO refactor move the hooks and corresponding actions into a "concern"
  before_action :initialize_memory_cache
  before_action :locale
  before_action :store_user_location!, if: :storable_location?

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to new_user_session_url
  end

  def initialize_memory_cache
    NastyCache.instance.initialize_request
  end

  def locale
    # update session if passed

    if params[:locale]
      session[:locale] = params[:locale]
      redirect_to(params.permit!.except(:locale)) if request.get?
    end

    # set locale based on session or url
    I18n.locale = session[:locale] || 'en'
  end

  ##
  # Shortcut for benchmarking of controller stuff.
  #
  # DEPRECATED: Use ActiveSupport notifications if possible.
  #
  # (is public, so we can call it within a render block)
  #
  # @param log_message [String]
  # @param log_level
  #
  def benchmark(log_message, log_level = Logger::INFO,  &block)
    self.class.benchmark(log_message) do
      yield
    end
  end

  private

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_path
      throw(:abort)
    end
  end

  # Its important that the location is NOT stored if:
  # - The request method is not GET (non idempotent)
  # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
  #    infinite redirect loop.
  # - The request is an Ajax request as this can lead to very unexpected behaviour.
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || super
  end
end
