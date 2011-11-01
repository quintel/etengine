module Etsource
  class Commit
    attr_accessor :commit

    def initialize(commit)
      @etsource = Base.new
      @branch = @etsource.current_branch
      self.commit = @etsource.checkout_commit(commit)
    end

    def import!
      Gquery.transaction do
        GqlTestCases.new(@etsource).import!
        Gqueries.new(@etsource).import!
        Inputs.new(@etsource).import!
      end

      # Prevent a detached HEAD
      @etsource.checkout @branch

      update_client APP_CONFIG[:client_refresh_url]
    end

    def message
      commit.message
    end

    # makes a simple http request. Used to refresh remote caches
    #
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