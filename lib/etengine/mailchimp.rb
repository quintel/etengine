# frozen_string_literal: true

module ETEngine
  # Mailchimp is a module which provides a client for the Mailchimp API.
  module Mailchimp
    module_function

    def enabled?
      Settings.dig(:mailchimp, :list_url).present? && Settings.dig(:mailchimp, :api_key).present?
    end

    def client
      unless enabled?
        raise "Mailchimp is not configured. Please set the 'mailchimp.list_url' and " \
              "'mailchimp.api_key' settings."
      end

      Faraday.new(Settings.mailchimp.list_url) do |conn|
        conn.request(:authorization, :basic, '', Settings.mailchimp.api_key)
        conn.request(:json)
        conn.response(:json)
        conn.response(:raise_error)
      end
    end

    def subscriber_id(email)
      Digest::MD5.hexdigest(email.downcase)
    end

    # Fetches the subscriber information if it exists. Raises Faraday::ResourceNotFound if the
    # subscriber
    def fetch_subscriber(email)
      client.get("members/#{subscriber_id(email)}").body
    end

    # Returns if the e-mail address is subscribed to the newsletter.
    def subscribed?(email)
      %w[pending subscribed].include?(fetch_subscriber(email)['status'])
    rescue Faraday::ResourceNotFound
      false
    end
  end
end
