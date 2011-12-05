module Api
  class BaseController < ::ApplicationController
    before_filter :cors_set_access_control_headers
    
    # CORS pre-flight request. All OPTIONS requests pass through this action
    # http://blog.davelyon.net/cross-origin-resource-sharing-on-rails
    # Check CORS documentation to see which requests trigger the preflight.
    # 
    def cross_site_sharing
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = 'GET, PUT, POST, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With'
      headers['Access-Control-Max-Age'] = '1278000'
      headers['Content-Length'] = '0'
      headers['Content-Type'] = 'text/plain'
      render nothing: true, status: 200
    end
    
    protected
      
      # This method, used as a before_filter, is enouth to enable CORS on most
      # controller actions
      # 
      def cors_set_access_control_headers
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
        headers['Access-Control-Max-Age'] = "1728000"
      end
  end
end
