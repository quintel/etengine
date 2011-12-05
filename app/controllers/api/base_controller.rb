module Api
  class BaseController < ::ApplicationController
    # CORS pre-flight request. All OPTIONS requests pass through this action
    # http://blog.davelyon.net/cross-origin-resource-sharing-on-rails
    # 
    def cross_site_sharing
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = 'GET, PUT, POST, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With'
      headers['Access-Control-Max-Age'] = '1278000'
      headers['Content-Length'] = '0'
      headers['Content-Type'] = 'text/plain'
      render nothing: true, status: 200
    end
  end
end
