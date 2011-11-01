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
  end
end