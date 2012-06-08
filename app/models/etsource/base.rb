module Etsource
  # Proxy to the git operations
  #
  class Base
    include Singleton

    attr_accessor :base_dir, :cache_dataset, :cache_topology, :export_dir

    def initialize
      @base_dir       = ETSOURCE_DIR
      @export_dir     = ETSOURCE_EXPORT_DIR.gsub(/\/$/, '')
      @cache_topology = APP_CONFIG.fetch(:etsource_cache_topology,   true)
      @cache_dataset  = APP_CONFIG.fetch(:etsource_cache_dataset, true)
      @git = Git.open @base_dir
    end

    def self.loader(base_dir = nil)
      instance.base_dir   = base_dir if base_dir
      instance.export_dir = base_dir if base_dir
      Loader.instance
    end

    # If you work on the input module, this disables caching and will
    # always reload the Etsource from scratch.
    def cache_dataset?
      @cache_dataset
    end

    # set to true to force reloading the topology
    def cache_topology?
      @cache_topology
    end

    def commits
      @git.log
    end

    def get_latest_export_sha
      import_sha_file
    end

    # Exports a revision. Git doesn't have a command similar to `svn export`, so this
    # emulates it. The revision passed as parameter will be exported to the
    # APP_CONFIG[:etsource_export_dir]. The directory will first be deleted (to get rid
    # of stale files) unless you disable this in your config.yml.
    def export(sha_id)
      return false if APP_CONFIG[:etsource_disable_export]
      FileUtils.rm_rf(@export_dir)
      FileUtils.mkdir(@export_dir)
      system "cd #{@base_dir} && git archive #{sha_id} | tar -x -C #{@export_dir}"
      update_latest_import_sha(sha_id)
    end

    def refresh
      system "cd #{@base_dir} && git pull"
    end

    # branch operations
    #
    def current_branch
      @git.current_branch
    end

    def detached_branch?
      current_branch =~ /no branch/
    end

    def branches
      @git.branches.local.map(&:name)
    end

    def checkout(branch)
      @git.checkout branch
    end

    def update_latest_import_sha(sha)
      File.open(import_sha_file, 'w') {|f| f.write(sha)} rescue nil
    end

    def get_latest_import_sha
      File.read(import_sha_file) rescue nil
    end

    private

    def import_sha_file
      "#{Rails.root}/config/latest_etsource_import_sha"
    end
  end
end
