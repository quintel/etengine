class Etsource::CommitsController < ApplicationController
  layout 'etsource'

  authorize_resource :class => false

  # data/latest/etsource/commits/current
  def show
  end

  def index
    @etsource = Etsource::Base.new
    # @etsource.current_branch is sometimes (no branch) catch this
    @branch = params[:branch] || @etsource.current_branch || 'master'
    @etsource.checkout @branch
    @output = @etsource.refresh if params[:commit] == 'Refresh'
    @commits = @etsource.commits
    @branches = @etsource.branches
    @latest_import = get_latest_import_sha
  end

  def import
    @commit = Etsource::Commit.new(params[:id])
    @commit.import! and update_latest_import_sha(params[:id])
    flash.now[:notice] = "It is now a good idea to refresh the gquery cache on all clients (ETM, Mixer, ...)"
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
end
