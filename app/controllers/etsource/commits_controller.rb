class Etsource::CommitsController < ApplicationController
  layout 'application'

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

    @using_repository = APP_CONFIG[:etsource_export] == APP_CONFIG[:etsource_working_copy]
  end

  def import
    previous_rev = @etsource.get_latest_import_sha
    backup_dir   = backup_atlas_files!(previous_rev)

    new_revision = params[:id]

    log("Import #{ new_revision }")

    begin
      @etsource.export(new_revision)
      @commit.import!
      @etsource.update_latest_import_sha(new_revision)

      NastyCache.instance.expire!
    rescue Atlas::AtlasError, Refinery::RefineryError => ex
      if previous_rev.nil? || Rails.env.development?
        # If there is no previous commit (this may be a fresh deploy), we
        # have nothing to roll back to so we just re-raise the error.
        raise ex
      end

      revert!(previous_rev, backup_dir)

      @exception = ex
      render action: 'failure'
    else
      # Clients might need to flush their cache
      update_remote_client(APP_CONFIG[:client_refresh_url])
    ensure
      if backup_dir && backup_dir.directory?
        backup_dir.children.each(&:delete)
        backup_dir.delete
      end
    end
  end

  private

  def find_commit
    @commit = Etsource::Commit.new(params[:id])
  end

  def restart_web_server
    # @deprecated as of 2012-05. use NastyCache.expire!
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

  # Internal: Prior to importing a new commit, backs up the production-mode
  # files so that we can do a faster rollback.
  #
  # Returns the path to the backup directory (which can be deleted in its
  # entirety once the import is finished).
  def backup_atlas_files!(revision)
    # If there is no previous good commit, there's nothing to back up.
    return unless revision

    from_dir   = Etsource::Dataset::Import.loader.directory
    backup_dir = from_dir.join("backup-#{ revision }")

    FileUtils.mkdir_p(backup_dir) unless backup_dir.directory?
    FileUtils.cp_r(Pathname.glob(from_dir.join('*.yml')), backup_dir)

    backup_dir
  end

  # Internal: Reverts a new ETSource commit by bringing back the old Atlas
  # production mode files.
  #
  # Returns nothing.
  def revert!(revision, directory)
    @etsource.export(revision)
    @commit.import!
    @etsource.update_latest_import_sha(revision)

    original_dir = directory.dirname

    # Remove any partially calculated production mode files.
    Pathname.glob(original_dir.join('*.yml')).each(&:delete)

    # Then copy the old files back.
    FileUtils.cp_r(Pathname.glob(directory.join('*.yml')), original_dir)

    log("Revert to #{ revision }")
    NastyCache.instance.expire!(keep_atlas_dataset: true)
  end
end
