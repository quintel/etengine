module Etsource
  # Proxy to the git operations
  #
  class Base
    include Singleton

    def initialize
      @etsource_dir = APP_CONFIG[:etsource_dir] || 'etsource'
      @git = Git.open @etsource_dir
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

    def detached_branch?
      current_branch =~ /no branch/
    end

    # Returns the SHA of the current checked-out revision
    def current_rev
      @git.revparse 'HEAD'
    end
  end
end
