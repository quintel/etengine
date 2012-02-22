class Etsource::CommitsController < ApplicationController
  layout 'etsource'
  before_filter :find_commit, :only => [:import, :checkout]

  authorize_resource :class => false

  # data/latest/etsource/commits/current
  def show
  end

  def index
    @etsource = Etsource::Base.instance
    # @etsource.current_branch is sometimes (no branch) catch this
    @branch = params[:branch] || @etsource.current_rev || @etsource.current_branch || 'master'
    @etsource.checkout @branch
    @output = @etsource.refresh if params[:commit] == 'Refresh'
    @commits = @etsource.commits
    @branches = @etsource.branches - ['(no branch)']
    @latest_import = get_latest_import_sha
    @current_revision = @etsource.current_rev
  end

  def import
    @commit.import! and update_latest_import_sha(params[:id])
    restart_unicorn
    flash.now[:notice] = "It is now a good idea to refresh the gquery cache on all clients (ETM, Mixer, ...)"
  end

  def checkout
    @etsource = Etsource::Base.instance
    sha_id = params[:id]
    @etsource.checkout sha_id
    restart_unicorn
    redirect_to etsource_commits_path, :notice => "Checked out rev: #{sha_id}"
  end

  private

  def update_latest_import_sha(sha)
    File.open(sha_file, 'w') {|f| f.write(sha)} rescue nil
  end

  def get_latest_import_sha
    File.read(sha_file) rescue nil
  end

  def sha_file
    "#{Rails.root}/config/latest_etsource_import_sha"
  end

  def find_commit
    @commit = Etsource::Commit.new(params[:id])
  end

  def restart_unicorn
    system("kill -s USR2 `cat #{Rails.root}/tmp/pids/unicorn.pid`") rescue nil
  end
end
