module Etsource
  class Commit
    ATLAS_REPO      = Git.open(Gem.loaded_specs['atlas'].full_gem_path)
    REFINERY_REPO   = Git.open(Gem.loaded_specs['refinery'].full_gem_path)

    ATLAS_COMMIT    = ATLAS_REPO.log(1).first
    REFINERY_COMMIT = REFINERY_REPO.log(1).first

    # Represents a Git dependency in a given ETSource revision. Tracks the exact
    # version of the dependency which is required, and the version of that
    # dependency currently loaded in ETEngine.
    class Dependency
      attr_reader :loaded_commit, :needed_commit

      # Public: Creates a new Dependency
      #
      # repo          - The Git::Base repository for the dependency.
      # loaded_commit - The Git::Object::Commit which ETEngine has currently
      #                 loaded.
      # needed_rev    - The git revision of the dependency as it appears in the
      #                 ETSource Gemfile.
      #
      # Returns a Dependency.
      def initialize(repo, loaded_commit, needed_rev)
        @loaded_commit = loaded_commit
        @needed_commit = repo.gcommit(needed_rev)
      end

      # Public: Returns if both the loaded and needed commits are exactly the
      # same revision.
      def identical?
        loaded_commit.date == needed_commit.date
      rescue Git::GitExecuteError
        false
      end

      # Public: Returns if the needed revision is either the same as the loaded
      # one, OR is older and thus likely to work.
      def compatible?
        ! incompatible?
      end

      # Public: The dependency is incompatible with the current Engine if the
      # needed version is newer than the loaded one.
      def incompatible?
        needed_commit.date > loaded_commit.date
      rescue Git::GitExecuteError
        true
      end
    end # Dependency

    # --------------------------------------------------------------------------

    # Returns the Git::Commit object.
    attr_reader :gcommit

    # Public: Creates a new Commit, which represents a revision in the ETSource
    # repository.
    #
    # etsource - The current Etsource::Base instance.
    # gcommit  - A Git::Commit.
    #
    # Returns a Commit.
    def initialize(etsource, gcommit)
      @etsource = etsource
      @gcommit  = gcommit
    end

    # Public: Contains the dependency information for Atlas.
    def atlas
      @atlas ||= Dependency.new(
        ATLAS_REPO, ATLAS_COMMIT, gemfile_revision('atlas'))
    end

    # Public: Contains the dependency information for Refinery.
    def refinery
      @refinery ||= Dependency.new(
        REFINERY_REPO, REFINERY_COMMIT, gemfile_revision('refinery'))
    end

    # Public: The ETSource commit can be imported so long as neither of the
    # dependencies are incompatible with those required by the commit.
    #
    # Returns true or false.
    def can_import?
      (! atlas.incompatible?) && (! refinery.incompatible?)
    end

    # Public: Determines if any of the dependencies are older than those
    # currently loaded in ETEngine, thereby requiring the user to confirm the
    # import before it is performed.
    #
    # Returns true or false.
    def requires_confirmation?
      (! atlas.identical?) || (! refinery.identical?)
    end

    # Public: The Git SHA reference for the commit.
    #
    # Returns a string.
    def sha
      @gcommit.sha
    end

    #######
    private
    #######

    # Internal: Returns the contents of the Gemfile in the ETSource tree.
    def gemfile
      @gemfile ||= @gcommit.gtree.blobs['Gemfile.lock'].contents
    end

    # Internal: Reads the Gemfile in the ETSource commit, returning the "GIT"
    # section for the chosen gem.
    def gemfile_revision(gem)
      part = gemfile.split("\n\n").find do |str|
        str.include?("remote: git@github.com:quintel/#{ gem }.git")
      end

      part.match(/revision: ([a-f0-9]+)$/)[1]
    end
  end # Commit
end # Etsource
