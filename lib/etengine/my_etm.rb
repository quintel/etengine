# frozen_string_literal: true

module ETEngine
  # Handles communication with MyETM API.
  module MyEtm
    module_function

    # Returns a Faraday client configured to communicate with MyETM.
    def client
      @client ||= Faraday.new(url: myetm_url) do |conn|
        conn.request(:json)
        conn.response(:json)
        conn.response(:raise_error)
        conn.options.timeout = 5
      end
    end

    def myetm_url
      Settings.identity.issuer&.gsub(%r{/+$}, '') || 'http://localhost:3002'
    end
  end
end
