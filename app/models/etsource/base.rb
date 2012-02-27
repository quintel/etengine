module Etsource
  # anti-rsi: method to quickly access Etsource::Base.instance in console
  def self.base(base_dir = nil)
    Base.instance.base_dir = base_dir if base_dir
    Base.instance
  end

  # anti-rsi: method to quickly access Etsource::Loader.instance
  def self.loader(base_dir = nil)
    base(base_dir) if base_dir
    Loader.instance
  end


  # Proxy to the git operations
  #
  class Base
    include Singleton

    attr_accessor :base_dir

    def initialize
      @base_dir      = ETSOURCE_DIR
      @export_dir    = ETSOURCE_EXPORT_DIR
      @load_wizards  = APP_CONFIG.fetch(:etsource_load_wizards, false)
      @cache_dataset = APP_CONFIG.fetch(:etsource_cache_dataset, true)

      @git = Git.open @base_dir
    end

    # Should ETsource::Wizards be included?
    # true:  this makes the input_module work.
    # false: turn off to make sure the ETengine is not affected by the input_module
    def load_wizards?
      @load_wizards
    end

    # If you work on the input module, this disables caching and will
    # always reload the Etsource from scratch.
    def cache_dataset?
      @cache_dataset
    end

    def current_commit_id
      @git.gcommit("HEAD").sha
    end

    def commits
      @git.log
    end

    def branches
      @git.branches.local.map(&:name)
    end

    def checkout(branch)
      @git.checkout branch
    end

    def export(branch)
      FileUtils.rm_rf(@export_dir)
      FileUtils.mkdir(@export_dir)
      system "cd #{@base_dir} && git archive #{branch} | tar -x -C #{@export_dir}"
    end

    def refresh
      @git.pull
    end

    def checkout_commit(commit)
      commit = @git.gcommit(commit)
      @git.checkout(commit)
      commit
    end

    def current_branch
      @git.current_branch
    end

    def detached_branch?
      current_branch =~ /no branch/
    end

    # Returns the SHA of the current checked-out revision
    def current_rev
      @git.revparse 'HEAD' rescue "ERROR parsing HEAD"
    end
  end
end
