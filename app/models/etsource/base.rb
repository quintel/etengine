module Etsource
  # Proxy to the git operations
  #
  class Base
    def initialize
      @etsource_dir = APP_CONFIG[:etsource_dir] || 'etsource'
      @git = Git.open @etsource_dir
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

    def refresh
      @git.pull
    end

    def checkout_commit(commit)
      commit = @git.gcommit(commit)
      @git.checkout(commit)
      commit
    end

    def base_dir
      @etsource_dir
    end
    
    def current_branch
      @git.current_branch
    end
  end
end