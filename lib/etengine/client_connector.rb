# frozen_string_literal: true

module ETEngine
  # Decodes and verifies a JWT sent by MyETM.
  module ClientConnector
    module_function


    def client_app_client(user, client_app, scopes: [])
      debugger
      client_uri = client_uri_for(client_app)

      Faraday.new(client_uri) do |conn|
        conn.request(:authorization, 'Bearer', -> { decoded_token })
        conn.request(:json)
        conn.response(:json)
        conn.response(:raise_error)
      end
    end

    # Helper method to fetch the URI for the given client application.
    def client_uri_for(client_app)
      Settings.clients[client_app].uri || raise("No URI configured for client: #{client_app}")
    end
  end
end
