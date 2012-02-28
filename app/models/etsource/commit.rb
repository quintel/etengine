module Etsource
  class Commit
    attr_accessor :commit

    def initialize(commit)
      @etsource = Etsource::Base.instance
    end

    def import!
      Gquery.transaction do
        GqlTestCases.new(@etsource).import!
        Gqueries.new(@etsource).import!
        Inputs.new(@etsource).import!
      end

      Rails.cache.clear
      update_client APP_CONFIG[:client_refresh_url]
      true
    rescue
      false
    end

    def message
      commit.message
    end

    # makes a simple http request. Used to refresh remote caches
    # Latest releases of ETM use gquery keys, so this isn't needed anymore
    def update_client(url)
      return unless url
      require 'net/http'
      require 'uri'

      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
    rescue
      nil
    end
  end
end
