class ApplicationController < ActionController::Base
  # include ApplicationController::PerformanceProfiling
  include ApplicationController::GcDisabling
  include ApplicationController::ClientIdentification

  helper :all
  helper_method :current_user_session, :current_user

  # TODO refactor move the hooks and corresponding actions into a "concern"
  before_filter :initialize_memory_cache
  before_filter :locale

  rescue_from CanCan::AccessDenied do |exception|
    store_location
    redirect_to root_url, :alert => "I am sorry. You are not allowed here."
  end

  def initialize_memory_cache
    NastyCache.instance.initialize_request
  end

  def locale
    # update session if passed
    session[:locale] = params[:locale] if params[:locale]
    # set locale based on session or url
    I18n.locale =  session[:locale] || 'en'
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

    def store_location
      session[:redirect_to] = request.url
    end

    def clear_stored_location
      session[:redirect_to] = nil
    end

    def redirect_back_or_default(default = root_path)
      redirect_to(session[:redirect_to] || default)
      clear_stored_location
    end

    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to root_path
        return false
      end
    end
end
