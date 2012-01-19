module ApplicationController::ClientIdentification
  extend ActiveSupport::Concern

  # This client string is passed by ETFlex only at the moment. I'm checking the
  # params hash because JSONP requests won't send custom HTTP headers
  #
  def api_client_string
    request.headers['X-Api-Agent'] || params['x_api_agent']
  end
end
