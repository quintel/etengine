# frozen_string_literal: true

module ETEngine

  module Clients
    module_function

    def idp_client(user = nil)
      @idp_client ||= begin
        token = user ? ETEngine::TokenDecoder.fetch_token(user) : nil
        client(Settings.idp_url, token)
      end
    end

    def client(url, token)
      Faraday.new(url) do |conn|
        conn.request :authorization, 'Bearer', token
        conn.request :json
        conn.response :json
        conn.response :raise_error
      end
    end
  end
end
