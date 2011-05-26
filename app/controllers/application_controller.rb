class ApplicationController < ActionController::Base
  include ApplicationController::ExceptionHandling unless Rails.env.development?
  # include ApplicationController::PerformanceProfiling
  include ApplicationController::GcDisabling
  include SortableTable::App::Controllers::ApplicationController

  helper :all
  helper_method :current_user_session, :current_user

  # TODO refactor move the hooks and corresponding actions into a "concern"
  before_filter :initialize_current
  before_filter :locale

  if Rails.env.test?
    after_filter :assign_current_for_inspection_in_tests
  end
  after_filter :teardown_current
  

  if APP_CONFIG[:debug_qernel]
    rescue_from Qernel::QernelError, :with => :show_qernel_errors
    rescue_from Qernel::CalculationError, :with => :show_qernel_errors
    rescue_from Gql::GqlError, :with => :show_gql_errors
  end

  def show_qernel_errors(exception)
    @exception = exception
    render :file => 'pages/qernel_error', :layout => 'pages'
  end

  def show_gql_errors(exception)
    @exception = exception
    render :file => 'pages/gql_error', :layout => 'pages'
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

protected
  def initialize_current
    Current.session = session
    Current.subdomain = request.subdomains.first
  end

  def teardown_current
    Current.teardown_after_request!
  end

  def permission_denied
    flash[:error] = I18n.t("flash.not_allowed")
    session[:return_to] = url_for :overwrite_params => {}
    redirect_to login_path
  end

  def restrict_to_admin
    if current_user.andand.admin?
      true
    else
      permission_denied
      false
    end
  end

private
  def assign_current_for_inspection_in_tests
    @current = Current
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

end
