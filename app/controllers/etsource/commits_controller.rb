class Etsource::CommitsController < ApplicationController
  layout 'etsource'
  before_filter :find_commit, :only => [:import, :export]

  authorize_resource :class => false

  # data/latest/etsource/commits/current
  def show
  end

  def index
    @etsource = Etsource::Base.instance
    @branch = params[:branch] || @etsource.current_branch || 'master'
    @branch = 'master' if @etsource.detached_branch?
    @branches = @etsource.branches
    @etsource.checkout @branch
    @output = @etsource.refresh if params[:commit] == 'Refresh'
    @commits = @etsource.commits
    @latest_import = get_latest_import_sha
    @current_revision = get_latest_export_sha
  end

  def import
    @etsource = Etsource::Base.instance
    sha = params[:id]
    @etsource.checkout sha
    @commit.import! and update_latest_import_sha(sha) and update_latest_export_sha(sha)
    restart_unicorn
    flash.now[:notice] = "It is now a good idea to refresh the gquery cache on all clients (ETM, Mixer, ...)"
  end

  # This will export a revision into APP_CONFIG[:etsource_working_copy]
  def export
    @etsource = Etsource::Base.instance
    sha_id = params[:id]
    @etsource.export(sha_id) and update_latest_export_sha(sha_id)
    restart_unicorn
    redirect_to etsource_commits_path, :notice => "Checked out rev: #{sha_id}"
  end

  private

  def update_latest_export_sha(sha)
    File.open(export_sha_file, 'w') {|f| f.write(sha)} rescue nil
  end

  def get_latest_export_sha
    File.read(export_sha_file) rescue nil
  end

  def update_latest_import_sha(sha)
    File.open(import_sha_file, 'w') {|f| f.write(sha)} rescue nil
  end

  def get_latest_import_sha
    File.read(import_sha_file) rescue nil
  end

  def export_sha_file
    "#{Rails.root}/config/latest_etsource_export_sha"
  end

  def import_sha_file
    "#{Rails.root}/config/latest_etsource_import_sha"
  end

  def find_commit
    @commit = Etsource::Commit.new(params[:id])
  end

  def restart_unicorn
    system("kill -s USR2 `cat #{Rails.root}/tmp/pids/unicorn.pid`") rescue nil
  end
end
