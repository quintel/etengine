class Etsource::CommitsController < ApplicationController
  layout 'etsource'
  before_filter :find_commit, :only => :import
  before_filter :setup_etsource

  authorize_resource :class => false

  # data/latest/etsource/commits/current
  def show
  end

  def index
    @branch = params[:branch] || @etsource.current_branch || 'master'
    @branch = 'master' if @etsource.detached_branch?
    @branches = @etsource.branches
    @etsource.checkout @branch
    if params[:commit] == 'Refresh'
      @output = @etsource.refresh
      log "Refresh branch #{@branch}"
    end
    @commits = @etsource.commits
  end

  # Will import a revision to APP_CONFIG[:etsource_working_copy]
  # and store to db gqueries and inputs
  def import
    sha = params[:id]
    @etsource.export sha
    @commit.import! and @etsource.update_latest_import_sha(sha)
    log("Import #{sha}")
    flash.now[:notice] = "Flushing ETM client cache"
    EtCache.instance.expire!

    # clients might need to flush their cache
    update_remote_client APP_CONFIG[:client_refresh_url]
  end

  private

  def find_commit
    @commit = Etsource::Commit.new(params[:id])
  end

  def restart_web_server
    # @deprecated as of 2012-05. use EtCache.expire!
    if Rails.env.production?
      system("kill -s USR2 `cat #{Rails.root}/tmp/pids/unicorn.pid`") rescue nil
    else
      system "touch tmp/restart.txt"
    end
  end

  def setup_etsource
    @etsource = Etsource::Base.instance
  end

  # simple http request
  def update_remote_client(url)
    return unless url
    require 'net/http'
    require 'uri'

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
  rescue
    nil
  end

  def log(msg)
    @logger ||= Logger.new(Rails.root.join('log/etsource.log'))
    @logger.info "#{Time.new} #{current_user.email}: #{msg}"
  end
end
