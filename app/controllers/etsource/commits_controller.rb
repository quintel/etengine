class Etsource::CommitsController < ApplicationController
  layout 'etsource'
  before_filter :find_commit, :only => [:import, :export]
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
    @output = @etsource.refresh if params[:commit] == 'Refresh'
    @commits = @etsource.commits
  end

  # like export, but will update inputs and gqueries
  #
  def import
    sha = params[:id]
    @etsource.export sha
    @commit.import! and @etsource.update_latest_import_sha(sha) and @etsource.update_latest_export_sha(sha)
    flash.now[:notice] = "Flushing ETM client cache"
    Rails.cache.clear
    # clients might need to flush their cache
    update_remote_client APP_CONFIG[:client_refresh_url]
    restart_unicorn
  end

  # This will export a revision into APP_CONFIG[:etsource_working_copy]
  # No changes to the db
  #
  def export
    sha_id = params[:id]
    @etsource.export(sha_id)
    restart_unicorn
    redirect_to etsource_commits_path, :notice => "Checked out rev: #{sha_id}"
  end

  private

  def find_commit
    @commit = Etsource::Commit.new(params[:id])
  end

  def restart_unicorn
    system("kill -s USR2 `cat #{Rails.root}/tmp/pids/unicorn.pid`") rescue nil
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
end
