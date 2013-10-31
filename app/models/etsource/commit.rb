module Etsource
  class Commit
    # Represents a Git dependency in a given ETSource revision. Tracks the exact
    # version of the dependency which is required, and the version of that
    # dependency currently loaded in ETEngine.
    class Dependency
      attr_reader :loaded_rev, :needed_rev

      # Public: Creates a new Dependency
      #
      # spec       - The Gem::Specification with details of the currently-loaded
      #              dependency.
      # needed_rev - The git revision of the dependency as it appears in the
      #              ETSource Gemfile.
      #
      # Returns a Dependency.
      def initialize(spec, needed_rev)
        @repo       = Git.open(spec.full_gem_path)
        @loaded_rev = @repo.gcommit('HEAD').sha
        @needed_rev = needed_rev
      end

      # Public: Returns the Git::Object::Commit representing the revision of the
      # dependency which is currently loaded.
      def loaded_commit
        @loaded_commit ||= @repo.gcommit(loaded_rev)
      end

      # Public: Returns the Git::Object::Commit representing the revision of the
      # dependency which is desired.
      def needed_commit
        @needed_commit ||= @repo.gcommit(needed_rev)
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

    # Public: Creates a new Commit, which represents a revision in the ETSource
    # repository.
    #
    # etsource - The current Etsource::Base instance.
    # revision - A string SHA of the revision.
    #
    # Returns a Commit.
    def initialize(etsource, revision)
      @etsource = etsource
      @revision = revision

      @gcommit  = Git.open(@etsource.base_dir).gcommit(revision)
    end

    # Public: Contains the dependency information for Atlas.
    def atlas
      @atlas ||= Dependency.new(
        Gem.loaded_specs['atlas'], gemfile_revision('atlas'))
    end

    # Public: Contains the dependency information for Refinery.
    def refinery
      @refinery ||= Dependency.new(
        Gem.loaded_specs['refinery'], gemfile_revision('refinery'))
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

    #######
    private
    #######

    # Internal: Reads the Gemfile in the ETSource commit, returning the "GIT"
    # section for the chosen gem.
    def gemfile_revision(gem)
      parts = @gcommit.gtree.blobs['Gemfile.lock'].contents.split("\n\n")

      part = parts.find do |str|
        str.include?("remote: git@github.com:quintel/#{ gem }.git")
      end

      part.match(/revision: ([a-f0-9]+)$/)[1]
    end
  end # Commit
end # Etsource
