class Etsource::CommitsController < ApplicationController
  layout 'application'

  before_action :setup_etsource

  helper_method :can_import?
  helper_method :import_in_progress?

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
    # Prevent other processes from doing an import while this one is in
    # progress.
    (redirect_to(etsource_commits_path) ; return) unless can_import?

    @commit = Etsource::Base.instance.commit(params[:id])

    if @commit.requires_confirmation? && ! params[:force]
      # When a commit uses different Atlas and Refinery versions than are
      # currently loaded, seek confirmation from the user before proceeding.
      render action: 'confirm'
      return
    end

    Rails.cache.write(:etsi_semaphore, Time.now)

    previous_rev = @etsource.get_latest_import_sha
    backup_dir   = backup_atlas_files!(previous_rev)

    new_revision = params[:id]

    if previous_rev.nil?
      log("Import #{ new_revision } (no revert possible)")
    else
      log("Import #{ new_revision } (can revert to #{ previous_rev })")
    end

    begin
      @etsource.export(new_revision)
      NastyCache.instance.expire!
    rescue RuntimeError => ex
      if previous_rev.nil?
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

      Rails.cache.delete(:etsi_semaphore)
    end
  end

  private

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
    FileUtils.cp_r(Pathname.glob(from_dir.join('*.pack')), backup_dir)

    backup_dir
  end

  # Internal: Reverts a new ETSource commit by bringing back the old Atlas
  # production mode files.
  #
  # Returns nothing.
  def revert!(revision, directory)
    log("Revert to #{ revision }")

    @etsource.export(revision)

    original_dir = directory.dirname

    # Remove any partially calculated production mode files.
    Pathname.glob(original_dir.join('*.pack')).each(&:delete)

    # Then copy the old files back.
    FileUtils.cp_r(Pathname.glob(directory.join('*.pack')), original_dir)

    NastyCache.instance.expire!(keep_atlas_dataset: true)
  end

  # Returns if the user is permitted to import a new version of ETSource at this
  # time. If another import is already in progress, or the previous semaphore is
  # less than three minutes old, then the user may not import.
  def can_import?
    (APP_CONFIG[:etsource_export] != APP_CONFIG[:etsource_working_copy]) &&
    (! import_in_progress?)
  end

  # Returns if an import is currently being performed.
  def import_in_progress?
    semaphore = Rails.cache.read(:etsi_semaphore)
    semaphore && semaphore >= 3.minutes.ago
  end
end
