class ApplicationController < ActionController::Base
  include LayoutHelper
  include JavascriptHelper
  include SprocketsHelper

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

  def set_locale
    locale
    redirect_to :back
  end

  def locale
    # update session if passed
    session[:locale] = params[:locale] if params[:locale]
    # set locale based on session or url
    I18n.locale =  session[:locale] || get_locale_from_url
  end

  def get_locale_from_url
    # set locale based on host or default
    request.host.split(".").last == 'nl' ? 'nl' : I18n.default_locale
  end
  
  ##
  # Loads Qernel and GQL in the controller, so that exceptions can be catched
  # by the rescue_from Qernel::*Error and thus displayed a nice debug panel,
  # instead of the default error page.
  #
  def preload_gql
    Current.gql
  end

  # TODO make one generic method
  def page_update_constraints(page)
    Current.view.root.constraints.each do |constraint|
      benchmark("updating constraint: #{constraint.key}") do
        page << update_constraint(constraint)
      end
    end
  end

  def ensure_valid_browser
    unless ALLOWED_BROWSERS.include?(browser)
      #TODO: put text in translation files and translate!
      flash[:notice] = "Your browser is not completely supported. <small><a href='/pages/browser_support/'>more information</a></small>"
    end
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


  ##
  # Shortcut for Current.setting
  #
  def setting
    Current.setting
  end

  

  def redirect_from_root
    if true # !Current.already_shown?('/pages/intro') or always_show_intro_screen?
      redirect_to :controller => 'pages', :action => 'intro'
    elsif c = setting.last_etm_controller_name and a = setting.last_etm_controller_action
      redirect_to :controller => c, :action => a
    else # this should actually not happen
      redirect_to :controller => 'pages', :action => 'intro'
    end
  end
  
  
  #
  # Redirect to params[:redirect_to] if if has been set. 
  #
  # Usage:
  #   redirect_to_if
  #
  # @untested 2010-12-21 jaap
  #
  def redirect_to_if(*args)
    if params[:redirect_to]
      redirect_to params[:redirect_to]
    else
      redirect_to(*args)
    end
  end
  
  
  
  def store_last_etm_page
    setting.last_etm_controller_name = params[:controller]
    setting.last_etm_controller_action = params[:action]
  end

  def ensure_settings_defined    
    if Current.scenario.country.nil? or Current.scenario.end_year.nil?
      redirect_to root_path
    end
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

  # TODO refactor into lib/browser.rb (seb 2010-10-11)
  def browser
    user_agent = request.env['HTTP_USER_AGENT']
    return 'firefox' if user_agent =~ /Firefox/
    return 'chrome' if user_agent =~ /Chrome/
    return 'safari' if user_agent =~ /Safari/
    return 'opera' if user_agent =~ /Opera/
    return 'ie9' if user_agent =~ /MSIE 9/
    return 'ie8' if user_agent =~ /MSIE 8/
    return 'ie7' if user_agent =~ /MSIE 7/
    return 'ie6' if user_agent =~ /MSIE 6/
  end
end

